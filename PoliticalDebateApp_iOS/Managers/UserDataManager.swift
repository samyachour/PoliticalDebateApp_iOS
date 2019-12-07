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

    private let starredNetworkService = NetworkService<StarredAPI>()
    private let progressNetworkService = NetworkService<ProgressAPI>()

    // MARK: - Global state

    // Private

    // Using set/dict for fast lookup
    private var starredRelay = BehaviorRelay<Set<PrimaryKey>>(value: .init())
    private var allProgressRelay = BehaviorRelay<[AnyHashable: Progress]>(value: .init())

    // Internal

    lazy var starredDriver = starredRelay.asDriver()
    lazy var allProgressDriver = allProgressRelay.asDriver()

    var starredArray: [PrimaryKey] { return Array(starredRelay.value) }
    var allProgressArray: [Progress] { return allProgressRelay.value.map { $0.value } }

    // MARK: - Setters

    // Private

    private func updateStarred(_ primaryKey: PrimaryKey, unstar: Bool = false) {
        var starred = starredRelay.value
        if unstar {
            starred.remove(primaryKey)
        } else {
            starred.insert(primaryKey)
        }
        starredRelay.accept(starred)
    }

    private func updateProgress(pointPrimaryKey: PrimaryKey,
                                debatePrimaryKey: PrimaryKey) {
        var allProgress = allProgressRelay.value
        if let debateProgress = allProgress[debatePrimaryKey] {
            if !debateProgress.seenPoints.contains(pointPrimaryKey) {
                var seenPoints = debateProgress.seenPoints
                seenPoints.append(pointPrimaryKey)
                allProgress[debatePrimaryKey] = Progress(debatePrimaryKey: debatePrimaryKey, seenPoints: seenPoints)
            }
        } else {
            let seenPoints = [pointPrimaryKey]
            allProgress[debatePrimaryKey] = Progress(debatePrimaryKey: debatePrimaryKey, seenPoints: seenPoints)
        }
        allProgressRelay.accept(allProgress)
    }

    // Internal

    func clearUserData() {
        starredRelay.accept(.init())
        allProgressRelay.accept(.init())
    }

    func isStarred(_ debatePrimaryKey: PrimaryKey) -> Bool {
        return starredRelay.value.contains(debatePrimaryKey)
    }

    func starOrUnstarDebate(_ primaryKey: PrimaryKey, unstar: Bool) -> Single<Response?> {
        guard !starredRelay.value.contains(primaryKey) && !unstar ||
            starredRelay.value.contains(primaryKey) && unstar else {
            return .just(nil) // already have this data
        }

        if SessionManager.shared.isActive {
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

    func getProgress(for debatePrimaryKey: PrimaryKey) -> Progress {
        var allProgress = allProgressRelay.value
        if let debateProgress = allProgress[debatePrimaryKey] {
            return debateProgress
        } else {
            let debateProgress = Progress(debatePrimaryKey: debatePrimaryKey, seenPoints: [])
            allProgress[debatePrimaryKey] = debateProgress
            allProgressRelay.accept(allProgress)
            return debateProgress
        }
    }

    func markProgress(pointPrimaryKey: PrimaryKey,
                      debatePrimaryKey: PrimaryKey) -> Single<Response?> {
        guard !(allProgressRelay.value[debatePrimaryKey]?.seenPoints.contains(pointPrimaryKey) ?? false) else {
            return .just(nil) // already have this data
        }

        if SessionManager.shared.isActive {
            return progressNetworkService.makeRequest(with: .saveProgress(debatePrimaryKey: debatePrimaryKey, pointPrimaryKey: pointPrimaryKey))
                .do(onSuccess: { (_) in
                    self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
                }).map { $0 as Response? }
        } else {
            ProgressCoreDataAPI.saveProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
            updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
            return Single.create {
                $0(.success(nil))
                return Disposables.create()
            }
        }
    }

    func markBatchProgress(pointPrimaryKeys: [PrimaryKey],
                           debatePrimaryKey: PrimaryKey) -> Single<Response?> {
        let newPointPrimaryKeys = pointPrimaryKeys
            .filter({ !(allProgressRelay.value[debatePrimaryKey]?.seenPoints.contains($0) ?? false) })
        guard !newPointPrimaryKeys.isEmpty else { return .just(nil) } // already have this data

        if SessionManager.shared.isActive {
            let debateProgress = Progress(debatePrimaryKey: debatePrimaryKey,
                                          seenPoints: newPointPrimaryKeys)
            return progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: BatchProgress(allDebatePoints: [debateProgress])))
                .do(onSuccess: { (_) in
                    newPointPrimaryKeys.forEach { (pointPrimaryKey) in
                        self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
                    }
                }).map { $0 as Response? }
        } else {
            newPointPrimaryKeys.forEach { (pointPrimaryKey) in
                ProgressCoreDataAPI.saveProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
                self.updateProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey)
            }
            return Single.create {
                $0(.success(nil))
                return Disposables.create()
            }
        }
    }

    /// Remove local points that don't exist on the backend anymore
    func removeStaleLocalPoints(from debate: Debate) {
        let localSeenPoints = getProgress(for: debate.primaryKey).seenPoints
        let allDebatePointsPrimaryKeys = debate.allPointsPrimaryKeys
        localSeenPoints.filter { primaryKey -> Bool in
            return !allDebatePointsPrimaryKeys.contains(primaryKey)
        }.forEach { primaryKey in
            ProgressCoreDataAPI.removePoint(primaryKey)
        }
    }

    // MARK: - Saving/Loading user data

    // Private

    private lazy var userDataLoadedRelay = BehaviorRelay<(firstEmission: Bool, loaded: Bool)>(value: (true, false))

    private func loadStarred(_ completion: @escaping (_ error: Error?) -> Void) {
        if SessionManager.shared.isActive {
            _ = starredNetworkService.makeRequest(with: .loadAllStarred)
                .map(Starred.self)
                .subscribe(onSuccess: { starred in
                    self.starredRelay.accept(Set(starred.starredList))
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
                                                                                                    bannerWasIgnored: {
                                                                                                        completion(UserDataError.loadRemoteStarred)
                    }))
            }
        } else {
            if let localStarred = StarredCoreDataAPI.loadAllStarred() {
                starredRelay.accept(Set(localStarred.starredList))
                completion(nil)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your starred debates from local data.",
                                                                                                buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                           action: {
                                                                                                                            self.loadStarred { error in completion(error) }
                                                                                                }),
                                                                                                bannerWasIgnored: {
                                                                                                    completion(UserDataError.loadLocalStarred)
                }))
            }
        }
    }

    private func loadProgress(_ completion: @escaping (_ error: Error?) -> Void) {
        if SessionManager.shared.isActive {
            _ = progressNetworkService.makeRequest(with: .loadAllProgress)
            .map([Progress].self)
                .subscribe(onSuccess: { (allProgress) in
                    self.allProgressRelay.accept(Dictionary(uniqueKeysWithValues: allProgress.map { ($0.debatePrimaryKey, $0) }))
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
                                                                                                    bannerWasIgnored: {
                                                                                                        completion(UserDataError.loadRemoteProgress)
                    }))
            }
        } else {
            if let localProgress = ProgressCoreDataAPI.loadAllProgress() {
                let localProgressFiltered = localProgress.compactMap { (progress) -> Progress? in
                    if progress == nil {
                        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                        title: "Couldn't load all your debates' progress from local data."))
                    }
                    return progress
                }
                allProgressRelay.accept(Dictionary(uniqueKeysWithValues: localProgressFiltered.map { ($0.debatePrimaryKey, $0) }))
                completion(nil)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your debates' progress from local data.",
                                                                                                buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                           action: {
                                                                                                                            self.loadProgress { error in completion(error) }
                                                                                                }),
                                                                                                bannerWasIgnored: {
                                                                                                    completion(UserDataError.loadLocalProgress)
                }))
            }
        }
    }

    // Internal

    /// Emits the first time the client loads the user's data
    var userDataLoadedSingle: Single<Bool> {
        let userDataLoaded = userDataLoadedRelay.value
        guard userDataLoaded.firstEmission else { return .just(userDataLoaded.loaded) }

        return userDataLoadedRelay.filter({ !$0.firstEmission })
            .take(1).asSingle().map({ return $1 })
    }
    /// Emits every time after the intiial loading of user data
    lazy var userDataLoadedDriver: Driver<Bool> = {
        return userDataLoadedRelay.asDriver().filter({ !$0.firstEmission })
            .skip(1).map({ return $1 })
    }()

    func loadUserData() {

        let loadUserData = {
            self.loadStarred { starredError in
                // Called after completion in case loadStarred refreshes the access token
                self.loadProgress { progressError in
                    guard starredError == nil && progressError == nil else {
                        self.userDataLoadedRelay.accept((false, false))
                        return
                    }

                    self.userDataLoadedRelay.accept((false, true))
                }
            }
        }

        if !SessionManager.shared.isActive {
            CoreDataService.loadPersistentContainer { error in
                guard error == nil else { return }

                loadUserData()
            }
        } else {
            loadUserData()
        }

    }

    func saveUserData() {
        guard !SessionManager.shared.isActive else { return }

        CoreDataService.saveContext()
    }

    // MARK: - Synchronizing local data w/ backend

    // Private

    private func syncLocalStarredDataToBackend(_ completion: @escaping () -> Void) {
        guard !starredRelay.value.isEmpty else {
            completion()
            return
        }

        _ = starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starredArray, unstarred: [])).subscribe(onSuccess: { _ in
            // We've successfully sync'd the local data to the backend, now we can clear it
            StarredCoreDataAPI.clearAllStarred()
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Successfully synced your local starred data to the cloud."))
            completion()
        }) { error in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                completion()
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
            completion()
        }
    }

    private var legitimateProgress: [Progress] {
        return allProgressArray.filter({ !$0.seenPoints.isEmpty })
    }

    private func syncLocalProgressDataToBackend(_ completion: @escaping () -> Void) {
        guard !legitimateProgress.isEmpty else {
            completion()
            return
        }

        _ = progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: BatchProgress(allDebatePoints: legitimateProgress)))
            .subscribe(onSuccess: { (_) in
                // We've successfully sync'd the local data to the backend, now we can clear it
                ProgressCoreDataAPI.clearAllProgress()
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Successfully synced your local progress data to the cloud."))
                completion()
            }) { (error) in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    completion()
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
                completion()
        }
    }

    // Internal

    var hasLocalDataToSync: Bool {
        return !legitimateProgress.isEmpty || !starredRelay.value.isEmpty
    }

    func syncUserDataToBackend() {
        syncLocalStarredDataToBackend {
            self.syncLocalProgressDataToBackend {
                // Need to make sure we've posted to the backend before retrieving the latest user data from it
                self.loadUserData()
            }
        }
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
