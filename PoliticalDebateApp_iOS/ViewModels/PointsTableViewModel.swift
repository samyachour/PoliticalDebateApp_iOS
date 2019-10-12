//
//  PointsTableViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

enum PointsTableViewState {
    case standalone // Listing all debate points in standalone VC
    case embeddedRebuttals // Embedding table of rebuttals in point VC
}

class PointsTableViewModel: StarrableViewModel {

    init(debate: Debate,
         isStarred: Bool = false,
         viewState: PointsTableViewState,
         rebuttals: [Point]? = nil) {
        self.debate = debate
        self.isStarred = isStarred
        self.viewState = viewState
        self.rebuttals = rebuttals
        subscribePointsUpdates()
    }

    private let disposeBag = DisposeBag()
    let viewState: PointsTableViewState

    // MARK: - Datasource

    private let pointsDataSourceRelay = BehaviorRelay<[PointTableViewCellViewModel]>(value: [])
    lazy var sharedPointsDataSourceRelay = pointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    private let contextPointsDataSourceRelay = BehaviorRelay<[Point]>(value: [])
    lazy var sharedContextPointsDataSourceRelay = contextPointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    let pointsRetrievalErrorRelay = PublishRelay<Error>()

    private lazy var pointsRelay = BehaviorRelay<[Point]>(value: debate.debateMap ?? [])
    private var rebuttals: [Point]? // Only used for embedded rebuttals table

    private lazy var seenPointsRelay = BehaviorRelay<[PrimaryKey]>(value: UserDataManager.shared.getProgress(for: debate.primaryKey).seenPoints)

    var debate: Debate
    var isStarred: Bool

    private func subscribePointsUpdates() {
        BehaviorRelay.combineLatest(pointsRelay, seenPointsRelay) { return ($0, $1) }
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                let pointsMatch = lhs.0 == rhs.0
                let seenPointsMatch = lhs.1 == rhs.1

                return pointsMatch && seenPointsMatch
        }.subscribe(onNext: { [weak self] (points, seenPoints) in
            guard let debatePrimaryKey = self?.debate.primaryKey else { return }

            self?.pointsDataSourceRelay.accept(points.map({ PointTableViewCellViewModel(point: $0,
                                                                                        debatePrimaryKey: debatePrimaryKey,
                                                                                        seenPoints: seenPoints) }))
        }).disposed(by: disposeBag)
    }

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

    func retrieveAllDebatePoints() {
        // Only should load all debate points if we're on the main standalone debate points view and don't already have the debate map
        guard viewState == .standalone && pointsRelay.value.isEmpty else {
            if let rebuttals = rebuttals {
                pointsRelay.accept(rebuttals)
            }
            return
        }

        debateNetworkService.makeRequest(with: .debate(primaryKey: debate.primaryKey))
            .map(Debate.self)
            .subscribe(onSuccess: { [weak self] debate in
                guard let debateMap = debate.debateMap,
                    let contextPoints = debate.contextPoints,
                    !debateMap.isEmpty else {
                        ErrorHandler.showBasicReportErrorBanner()
                        return
                }
                self?.pointsRelay.accept(debateMap)
                self?.contextPointsDataSourceRelay.accept(contextPoints)
                self?.debate = debate
            }) { [weak self] error in
                self?.pointsRetrievalErrorRelay.accept(error)
            }.disposed(by: disposeBag)
    }

    func refreshSeenPoints() { seenPointsRelay.accept(UserDataManager.shared.getProgress(for: debate.primaryKey).seenPoints) }

    func markContextPointsAsSeen() {
        contextPointsDataSourceRelay.value.forEach({ [weak self] (point) in
            guard let self = self else { return }

            // Don't care if this call succeeds or fails
            UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                                debatePrimaryKey: debate.primaryKey,
                                                totalPoints: debate.totalPoints).subscribe().disposed(by: self.disposeBag)
        })
    }

}
