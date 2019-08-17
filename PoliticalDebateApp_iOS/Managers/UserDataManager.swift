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

    var starred = Set<PrimaryKey>()
    var starredArray: [PrimaryKey] { return Array(starred) }

    var progress = Set<Progress>()
    var progressArray: [Progress] { return Array(progress) }

    // MARK: - Setters

    func clearUserData() {
        clearStarred()
        clearProgress()
    }

    private func clearStarred() {
        starred.removeAll()
    }

    private func clearProgress() {
        progress.removeAll()
    }

    func starOrUnstarDebate(_ primaryKey: PrimaryKey, unstar: Bool) -> Single<Response?> {
        if SessionManager.shared.isActiveRelay.value {
            let starred = unstar ? [] : [primaryKey]
            let unstarred = unstar ? [primaryKey] : []
            return starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starred, unstarred: unstarred)).do(onSuccess: { (_) in
                // Can capture self since it's a singleton, always in memory
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

    func markProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) -> Single<Response?> {
        if SessionManager.shared.isActiveRelay.value {
            return progressNetworkService.makeRequest(with: .saveProgress(debatePrimaryKey: debatePrimaryKey, pointPrimaryKey: pointPrimaryKey))
                .do(onSuccess: { (_) in
                    // Can capture self since it's a singleton, always in memory
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

    // TODO: Pass in progress object to this so I can utilize remove instead of firstIndex
    private func updateProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) {
        if let debateProgressIndex = progress.firstIndex(where: {$0.debatePrimaryKey == debatePrimaryKey}) {
            var seenPoints = progress[debateProgressIndex].seenPoints ?? []
            seenPoints.append(pointPrimaryKey)
            let completedPercentage = Float(seenPoints.count) / Float(totalPoints)
            progress.remove(at: debateProgressIndex)
            progress.insert(Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints))
        } else {
            let seenPoints = [pointPrimaryKey]
            let completedPercentage = Float(seenPoints.count) / Float(totalPoints)
            progress.insert(Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints))
        }
    }

    // MARK: - Loading user data

    func loadUserData(_ completion: (() -> Void)? = nil) {

        let loadUserData = {
            // Can capture self since it's a singleton, always in memory
            self.loadStarred {
                // Called after completion in case loadStarred refreshes the access token
                self.loadProgress {
                    completion?()
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

    private func loadStarred(_ completion: @escaping () -> Void) {
        if SessionManager.shared.isActiveRelay.value {
            starredNetworkService.makeRequest(with: .loadAllStarred)
                .map(Starred.self)
                .subscribe(onSuccess: { starred in
                    // Can capture self since it's a singleton, always in memory
                    self.starred = Set(starred.starredList)
                    completion()
                }) { error in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your starred debates from the server."))
                    completion()
            }.disposed(by: disposeBag)
        } else {
            if let localStarred = StarredCoreDataAPI.loadAllStarred() {
                self.starred = Set(localStarred.starredList)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your starred debates from local data."))
            }
            completion()
        }
    }

    private func loadProgress(_ completion: @escaping () -> Void) {
        if SessionManager.shared.isActiveRelay.value {
            progressNetworkService.makeRequest(with: .loadAllProgress)
            .map([Progress].self)
                .subscribe(onSuccess: { (allProgress) in
                    self.progress = Set(allProgress)
                    completion()
                }) { (error) in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your debates' progress from the server."))
                    completion()
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
                progress = Set(localProgressFiltered)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your debates' progress from local data."))
            }
            completion()
        }
    }

    // MARK: - Synchronizing local data w/ backend

    func syncUserDataToBackend() {
        syncLocalStarredDataToBackend {
            // Can capture self since it's a singleton, always in memory
            self.syncLocalProgressDataToBackend {
                // Need to make sure we've posted to the backend before retrieving the latest user data from it
                self.loadUserData() // Backend syncing is typically called after the user is newly authenticated
            }
        }
    }

    private func syncLocalStarredDataToBackend(_ completion: @escaping () -> Void) {
        guard !starred.isEmpty else {
            completion()
            return
        }

        starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starredArray, unstarred: [])).subscribe(onSuccess: { (_) in
            // We've successfully sync'd the local data to the backend, now we can clear it
            StarredCoreDataAPI.clearAllStarred()
            completion()
        }) { (error) in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            NotificationBannerQueue.shared
                .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                  title: "Could not sync your local starred data to the server.",
                                                                  buttonConfig: NotificationBannerViewModel
                                                                    .ButtonConfiguration.customTitle(title: "Retry",
                                                                                                     action: {
                                                                                                        self.syncLocalStarredDataToBackend(completion)
                                                                    })))
            completion()
        }.disposed(by: disposeBag)
    }

    private func syncLocalProgressDataToBackend(_ completion: @escaping () -> Void) {
        guard !progress.isEmpty else {
            completion()
            return
        }

        progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: progressArray))
            .subscribe(onSuccess: { (_) in
                // We've successfully sync'd the local data to the backend, now we can clear it
                ProgressCoreDataAPI.clearAllProgress()
                completion()
            }) { (error) in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                      title: "Could not sync your local progress data to the server.",
                                                                      buttonConfig: NotificationBannerViewModel
                                                                        .ButtonConfiguration.customTitle(title: "Retry",
                                                                                                         action: {
                                                                                                            self.syncLocalProgressDataToBackend(completion)
                                                                        })))
                completion()
        }.disposed(by: disposeBag)
    }
}
