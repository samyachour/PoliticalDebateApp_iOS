//
//  UserDataManager.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

// Handling reading/updating user data whether or not they are authenticated
class UserDataManager {

    static let shared = UserDataManager()

    private init() {}

    private let disposeBag = DisposeBag()

    private let starredNetworkService = NetworkService<StarredAPI>()
    private let progressNetworkService = NetworkService<ProgressAPI>()

    // MARK: - Global state

    // Using set/dict for fast lookup
    private var starred = Set<PrimaryKey>()
    private var allProgress = [AnyHashable: Progress]()

    var starredArray: [PrimaryKey] { return Array(starred) }
    var allProgressArray: [Progress] { return allProgress.map { $0.value } }

    // MARK: - Setters

    func clearUserData() {
        clearStarred()
        clearProgress()
    }

    private func clearStarred() {
        starred.removeAll()
    }

    private func clearProgress() {
        allProgress.removeAll()
    }

    func isStarred(_ debatePrimaryKey: PrimaryKey) -> Bool {
        return starred.contains(debatePrimaryKey)
    }

    func starOrUnstarDebate(_ primaryKey: PrimaryKey, unstar: Bool) -> Single<Response?> {
        guard !starred.contains(primaryKey) && !unstar ||
            starred.contains(primaryKey) && unstar else {
            return .just(nil) // already have this data
        }

        if SessionManager.shared.isActiveRelay.value {
            let starred = unstar ? [] : [primaryKey]
            let unstarred = unstar ? [primaryKey] : []
            return starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starred, unstarred: unstarred))
                .do(onSuccess: { (_) in
                    self.updateStarred(primaryKey, unstar: unstar)
                }).map { $0 as Response? }
        } else {
            StarredCoreDataAPI.starOrUnstarDebate(primaryKey, unstar: unstar)
            updateStarred(primaryKey, unstar: unstar)
            return Single.create {
                $0(.success(nil))
                return Disposables.create()
            }
        }
    }

    private func updateStarred(_ primaryKey: PrimaryKey, unstar: Bool = false) {
        if unstar {
            starred.remove(primaryKey)
        } else {
            starred.insert(primaryKey)
        }
    }

    func getProgress(for debatePrimaryKey: PrimaryKey) -> Progress {
        if let debateProgress = allProgress[debatePrimaryKey] {
            return debateProgress
        } else {
            let debateProgress = Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: 0, seenPoints: [])
            allProgress[debatePrimaryKey] = debateProgress
            return debateProgress
        }
    }

    func markProgress(pointPrimaryKey: PrimaryKey,
                      debatePrimaryKey: PrimaryKey,
                      totalPoints: Int) -> Single<Response?> {
        guard !(allProgress[debatePrimaryKey]?.seenPoints.contains(pointPrimaryKey) ?? false) else {
            return .just(nil) // already have this data
        }

        if SessionManager.shared.isActiveRelay.value {
            return progressNetworkService.makeRequest(with: .saveProgress(debatePrimaryKey: debatePrimaryKey, pointPrimaryKey: pointPrimaryKey))
                .do(onSuccess: { (_) in
                    self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
                }).map { $0 as Response? }
        } else {
            ProgressCoreDataAPI.saveProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
            updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
            return Single.create {
                $0(.success(nil))
                return Disposables.create()
            }
        }
    }

    func markBatchProgress(pointPrimaryKeys: [PrimaryKey],
                           debatePrimaryKey: PrimaryKey,
                           totalPoints: Int) -> Single<Response?> {
        guard !pointPrimaryKeys.isEmpty,
            allProgress[debatePrimaryKey]?.seenPoints.allSatisfy({ !pointPrimaryKeys.contains($0) }) ?? true else {
            return .just(nil) // already have this data
        }

        if SessionManager.shared.isActiveRelay.value {
            let debateProgress = Progress(debatePrimaryKey: debatePrimaryKey,
                                          completedPercentage: 0, // doesn't get sent to the backend anyway
                                          seenPoints: pointPrimaryKeys)
            return progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: BatchProgress(allDebatePoints: [debateProgress])))
                .do(onSuccess: { (_) in
                    pointPrimaryKeys.forEach { (pointPrimaryKey) in
                        self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
                    }
                }).map { $0 as Response? }
        } else {
            pointPrimaryKeys.forEach { (pointPrimaryKey) in
                ProgressCoreDataAPI.saveProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
                self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
            }
            return Single.create {
                $0(.success(nil))
                return Disposables.create()
            }
        }
    }

    private func updateProgress(pointPrimaryKey: PrimaryKey,
                                debatePrimaryKey: PrimaryKey,
                                totalPoints: Int) {
        if let debateProgress = allProgress[debatePrimaryKey],
            !debateProgress.seenPoints.contains(pointPrimaryKey) {
            var seenPoints = debateProgress.seenPoints
            seenPoints.append(pointPrimaryKey)
            let completedPercentage = (Float(seenPoints.count) / Float(totalPoints)) * 100
            allProgress[debatePrimaryKey] = Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints)
        } else {
            let seenPoints = [pointPrimaryKey]
            let completedPercentage = (Float(seenPoints.count) / Float(totalPoints)) * 100
            allProgress[debatePrimaryKey] = Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints)
        }
    }

    // MARK: - Loading user data

    private let userDataLoadedRelay = BehaviorRelay<Bool>(value: false)
    lazy var sharedUserDataLoadedRelay = userDataLoadedRelay
        .skip(1)
        .share(replay: 1, scope: .whileConnected)
    var userDataLoaded: Bool { return userDataLoadedRelay.value }

    func loadUserData() {

        let loadUserData = {
            self.loadStarred { starredError in
                // Called after completion in case loadStarred refreshes the access token
                self.loadProgress { progressError in
                    guard starredError == nil && progressError == nil else {
                        self.userDataLoadedRelay.accept(false)
                        return
                    }

                    self.userDataLoadedRelay.accept(true)
                }
            }
        }

        if !SessionManager.shared.isActiveRelay.value {
            CoreDataService.loadPersistentContainer { (error) in
                guard error == nil else { return }

                loadUserData()
            }
        } else {
            loadUserData()
        }

    }

    private func loadStarred(_ completion: @escaping (_ error: Error?) -> Void) {
        if SessionManager.shared.isActiveRelay.value {
            starredNetworkService.makeRequest(with: .loadAllStarred)
                .map(Starred.self)
                .subscribe(onSuccess: { starred in
                    self.starred = Set(starred.starredList)
                    completion(nil)
                }) { error in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your starred debates from the server.",
                                                                                                    buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                               action: {
                                                                                                                                self.loadStarred { error in completion(error) }
                                                                                                    }),
                                                                                                    bannerWasDismissedAutomatically: {
                                                                                                        completion(UserDataError.loadRemoteStarred)
                    }))
            }.disposed(by: disposeBag)
        } else {
            if let localStarred = StarredCoreDataAPI.loadAllStarred() {
                starred = Set(localStarred.starredList)
                completion(nil)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your starred debates from local data.",
                                                                                                buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                           action: {
                                                                                                                            self.loadStarred { error in completion(error) }
                                                                                                }),
                                                                                                bannerWasDismissedAutomatically: {
                                                                                                    completion(UserDataError.loadLocalStarred)
                }))
            }
        }
    }

    private func loadProgress(_ completion: @escaping (_ error: Error?) -> Void) {
        if SessionManager.shared.isActiveRelay.value {
            progressNetworkService.makeRequest(with: .loadAllProgress)
            .map([Progress].self)
                .subscribe(onSuccess: { (allProgress) in
                    self.allProgress = Dictionary(uniqueKeysWithValues: allProgress.map { ($0.debatePrimaryKey, $0) })
                    completion(nil)
                }) { (error) in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your debates' progress from the server.",
                                                                                                    buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                               action: {
                                                                                                                               self.loadProgress { error in completion(error) }
                                                                                                    }),
                                                                                                    bannerWasDismissedAutomatically: {
                                                                                                        completion(UserDataError.loadRemoteProgress)
                    }))
            }.disposed(by: disposeBag)
        } else {
            if let localProgress = ProgressCoreDataAPI.loadAllProgress() {
                let localProgressFiltered = localProgress.compactMap { (progress) -> Progress? in
                    if progress == nil {
                        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                        title: "Couldn't load all your debates' progress from local data."))
                    }
                    return progress
                }
                allProgress = Dictionary(uniqueKeysWithValues: localProgressFiltered.map { ($0.debatePrimaryKey, $0) })
                completion(nil)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your debates' progress from local data.",
                                                                                                buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                           action: {
                                                                                                                            self.loadProgress { error in completion(error) }
                                                                                                }),
                                                                                                bannerWasDismissedAutomatically: {
                                                                                                    completion(UserDataError.loadLocalProgress)
                }))
            }
        }
    }

    // MARK: - Synchronizing local data w/ backend

    func syncUserDataToBackend() {
        syncLocalStarredDataToBackend { starredSuccess in
            self.syncLocalProgressDataToBackend { progressSuccess in
                if starredSuccess && progressSuccess {
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                    title: "Successfully synced your local data to the cloud."))
                }
                // Need to make sure we've posted to the backend before retrieving the latest user data from it
                self.loadUserData() // Backend syncing is typically called after the user is newly authenticated
            }
        }
    }

    private func syncLocalStarredDataToBackend(_ completion: @escaping (Bool) -> Void) {
        guard !starred.isEmpty else {
            completion(true)
            return
        }

        starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starredArray, unstarred: [])).subscribe(onSuccess: { (_) in
            // We've successfully sync'd the local data to the backend, now we can clear it
            StarredCoreDataAPI.clearAllStarred()
            completion(true)
        }) { (error) in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            NotificationBannerQueue.shared
                .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                  title: "Could not sync your local starred data to the server.",
                                                                  subtitle: "Please try logging out and back in again.",
                                                                  buttonConfig: NotificationBannerViewModel
                                                                    .ButtonConfiguration.customTitle(title: GeneralCopies.retryTitle,
                                                                                                     action: {
                                                                                                        self.syncLocalStarredDataToBackend(completion)
                                                                    })))
            completion(false)
        }.disposed(by: disposeBag)
    }

    private func syncLocalProgressDataToBackend(_ completion: @escaping (Bool) -> Void) {
        let legitimateProgress = allProgressArray.filter({ !($0.seenPoints).isEmpty })
        guard !legitimateProgress.isEmpty else {
            completion(true)
            return
        }

        progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: BatchProgress(allDebatePoints: legitimateProgress)))
            .subscribe(onSuccess: { (_) in
                // We've successfully sync'd the local data to the backend, now we can clear it
                ProgressCoreDataAPI.clearAllProgress()
                completion(true)
            }) { (error) in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                      title: "Could not sync your local progress data to the server.",
                                                                      subtitle: "Please try logging out and back in again.",
                                                                      buttonConfig: NotificationBannerViewModel
                                                                        .ButtonConfiguration.customTitle(title: GeneralCopies.retryTitle,
                                                                                                         action: {
                                                                                                            self.syncLocalProgressDataToBackend(completion)
                                                                        })))
                completion(false)
        }.disposed(by: disposeBag)
    }
}

enum UserDataError: Error {
    case loadRemoteStarred
    case loadLocalStarred
    case loadRemoteProgress
    case loadLocalProgress

    var localizedDescription: String {
        switch self {
        case .loadRemoteStarred:
            return "Could not load remote starred."
        case .loadLocalStarred:
            return "Could not load local starred."
        case .loadRemoteProgress:
            return "Could not load remote progress."
        case .loadLocalProgress:
            return "Could not load local progress."
        }
    }
}
