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

    // MARK: - Global (private) state

    private let starredRelay = BehaviorRelay<[PrimaryKey]>(value: [])

    private let progressRelay = BehaviorRelay<[Progress]>(value: [])

    // MARK: - Getters

    var starredRelayValue: [PrimaryKey] {
        return starredRelay.value
    }

    var progressRelayValue: [Progress] {
        return progressRelay.value
    }

    lazy var starredRelayProducer: Driver<[PrimaryKey]> = {
        return starredRelay.asDriver()
    }()

    lazy var progressRelayProducer: Driver<[Progress]> = {
        return progressRelay.asDriver()
    }()

    // MARK: - Setters

    func starDebate(_ primaryKey: PrimaryKey) -> Single<Response>? {
        if SessionManager.shared.isActiveRelay.value {
            return starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: [primaryKey], unstarred: [])).do(onSuccess: { (_) in
                // Can capture self since it's a singleton, always in memory
                self.updateStarRelay(primaryKey)
            })
        } else {
            StarredCoreDataAPI.starOrUnstarDebate(primaryKey)
            updateStarRelay(primaryKey)
            return nil
        }
    }

    func unstarDebate(_ primaryKey: PrimaryKey) -> Single<Response>? {
        if SessionManager.shared.isActiveRelay.value {
            return starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: [], unstarred: [primaryKey])).do(onSuccess: { (_) in
                // Can capture self since it's a singleton, always in memory
                self.updateStarRelay(primaryKey, unstar: true)
            })
        } else {
            StarredCoreDataAPI.starOrUnstarDebate(primaryKey, unstar: true)
            updateStarRelay(primaryKey, unstar: true)
            return nil
        }
    }

    private func updateStarRelay(_ primaryKey: PrimaryKey, unstar: Bool = false) {
        var currentStarred = starredRelay.value
        if unstar {
            currentStarred.removeAll { $0 == primaryKey }
        } else {
            currentStarred.append(primaryKey)
        }
        starredRelay.accept(currentStarred)
    }

    func markProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) -> Single<Response>? {
        if SessionManager.shared.isActiveRelay.value {
            return progressNetworkService.makeRequest(with: .saveProgress(debatePrimaryKey: debatePrimaryKey, pointPrimaryKey: pointPrimaryKey))
                .do(onSuccess: { (_) in
                    // Can capture self since it's a singleton, always in memory
                    self.updateProgressRelay(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
                })
        } else {
            ProgressCoreDataAPI.saveProgress(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
            updateProgressRelay(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey, totalPoints: totalPoints)
            return nil
        }
    }

    private func updateProgressRelay(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) {
        var currentProgress = progressRelay.value
        if let debateProgressIndex = currentProgress.firstIndex(where: {$0.debatePrimaryKey == debatePrimaryKey}) {
            var seenPoints = currentProgress[debateProgressIndex].seenPoints ?? []
            seenPoints.append(pointPrimaryKey)
            let completedPercentage = Float(seenPoints.count) / Float(totalPoints)
            currentProgress[debateProgressIndex] = Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints)
        } else {
            let seenPoints = [pointPrimaryKey]
            let completedPercentage = Float(seenPoints.count) / Float(totalPoints)
            currentProgress.append(Progress(debatePrimaryKey: debatePrimaryKey, completedPercentage: Int(completedPercentage), seenPoints: seenPoints))
        }
        progressRelay.accept(currentProgress)
    }

    // MARK: - Loading user data

    func loadUserData() {

        let loadUserData = {
            // Can capture self since it's a singleton, always in memory
            self.loadStarred()
            self.loadProgress()
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

    private func loadStarred() {
        if SessionManager.shared.isActiveRelay.value {
            starredNetworkService.makeRequest(with: .loadAllStarred)
                .map(Starred.self)
                .subscribe(onSuccess: { starred in
                    // Can capture self since it's a singleton, always in memory
                    self.starredRelay.accept(starred.starredList)
                }) { error in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your starred debates from the server."))
            }.disposed(by: disposeBag)
        } else {
            if let localStarred = StarredCoreDataAPI.loadAllStarred() {
                starredRelay.accept(localStarred.starredList)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your starred debates from local data."))
            }
        }
    }

    private func loadProgress() {
        if SessionManager.shared.isActiveRelay.value {
            progressNetworkService.makeRequest(with: .loadAllProgress)
            .map([Progress].self)
                .subscribe(onSuccess: { (allProgress) in
                    self.progressRelay.accept(allProgress)
                }) { (error) in
                    if let generalError = error as? GeneralError,
                        generalError == .alreadyHandled {
                        return
                    }
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Couldn't load your debates' progress from the server."))
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
                progressRelay.accept(localProgressFiltered)
            } else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't load your debates' progress from local data."))
            }
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
        guard !starredRelay.value.isEmpty else {
            completion()
            return
        }

        starredNetworkService.makeRequest(with: .starOrUnstarDebates(starred: starredRelay.value, unstarred: [])).subscribe(onSuccess: { (_) in
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
        guard !progressRelay.value.isEmpty else {
            completion()
            return
        }

        progressNetworkService.makeRequest(with: .saveBatchProgress(batchProgress: progressRelay.value))
            .subscribe(onSuccess: { (_) in
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
