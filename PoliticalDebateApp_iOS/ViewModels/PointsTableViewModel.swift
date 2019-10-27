//
//  PointsTableViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Differentiator
import Moya
import RxCocoa
import RxDataSources
import RxSwift

enum PointsTableViewState {
    case standaloneRootPoints
    case embeddedPointHistory
    case embeddedRebuttals
}

struct PointsTableViewSection: AnimatableSectionModelType {
    var items: [SidedPointTableViewCellViewModel]
    var header = "" // Only using 1 section
    var identity: String { return header }

    init(items: [SidedPointTableViewCellViewModel]) {
        self.items = items
    }

    init(original: PointsTableViewSection, items: [SidedPointTableViewCellViewModel]) {
        self = original
        self.items = items
    }
}

class PointsTableViewModel: StarrableViewModel {

    init(debate: Debate,
         isStarred: Bool = false,
         viewState: PointsTableViewState,
         embeddedSidedPoints: [Point]? = nil) {
        self.debate = debate
        self.isStarred = isStarred
        self.viewState = viewState
        self.embeddedSidedPoints = embeddedSidedPoints
        subscribeSidedPointsUpdates()
        subscribeToContextPointsUpdates()

        UserDataManager.shared.sharedUserDataLoadedRelay
            .subscribe(onNext: { [weak self] loaded in
                guard loaded else { return }

                self?.refreshSeenPoints()
            }).disposed(by: disposeBag)
    }

    private let disposeBag = DisposeBag()
    let viewState: PointsTableViewState

    // MARK: - Datasource

    private let sidedPointsDataSourceRelay = BehaviorRelay<[PointsTableViewSection]>(value: [PointsTableViewSection(items: [])])
    lazy var sharedSidedPointsDataSourceRelay = sidedPointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    private let contextPointsDataSourceRelay = BehaviorRelay<[Point]>(value: [])
    lazy var sharedContextPointsDataSourceRelay = contextPointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    let pointsRetrievalErrorRelay = PublishRelay<Error>()

    private lazy var sidedPointsRelay = BehaviorRelay<[Point]>(value: debate.sidedPoints ?? [])
    private var embeddedSidedPoints: [Point]?

    private lazy var seenPointsRelay = BehaviorRelay<[PrimaryKey]>(value: UserDataManager.shared.getProgress(for: debate.primaryKey).seenPoints)

    var debate: Debate
    var isStarred: Bool

    private func subscribeSidedPointsUpdates() {
        BehaviorRelay.combineLatest(sidedPointsRelay, seenPointsRelay) { return ($0, $1) }
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                let pointsMatch = lhs.0 == rhs.0
                let seenPointsMatch = lhs.1 == rhs.1

                return pointsMatch && seenPointsMatch
        }.subscribe(onNext: { [weak self] (points, seenPoints) in
            guard let debatePrimaryKey = self?.debate.primaryKey,
                let viewState = self?.viewState,
                let currentSidedPointsDataSourceSection = self?.sidedPointsDataSourceRelay.value.first else {
                    return
            }

            let newSidedPointCellViewModels = points
                .map({ SidedPointTableViewCellViewModel(point: $0,
                                                        debatePrimaryKey: debatePrimaryKey,
                                                        seenPoints: seenPoints,
                                                        useFullDescription: viewState == .embeddedPointHistory) })
            self?.sidedPointsDataSourceRelay.accept([PointsTableViewSection(original: currentSidedPointsDataSourceSection, items: newSidedPointCellViewModels)])
        }).disposed(by: disposeBag)
    }

    private func subscribeToContextPointsUpdates() {
        sharedContextPointsDataSourceRelay
            .take(1).asSingle()
            .flatMap({ (contextPoints) -> Single<[Point]> in
                guard !UserDataManager.shared.userDataLoaded else { return .just(contextPoints) }

                return UserDataManager.shared.sharedUserDataLoadedRelay
                    .take(1).asSingle()
                    .map { loaded in return loaded ? contextPoints : [] }
            })
            .subscribe(onSuccess: { [weak self] contextPoints in
                guard let self = self else { return }

                // Don't care if this call succeeds or fails
                UserDataManager.shared
                    .markBatchProgress(pointPrimaryKeys: contextPoints.map { $0.primaryKey },
                                       debatePrimaryKey: self.debate.primaryKey,
                                       totalPoints: self.debate.totalPoints)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }

    // MARK: Point history updates

    func fea() {}

    // MARK: Rebuttals updates

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

    func retrieveAllDebatePoints() {
        // Only should load all debate points if we're on the main standalone debate points view and don't already have the debate map
        guard viewState == .standaloneRootPoints && sidedPointsRelay.value.isEmpty else {
            if let embeddedSidedPoints = embeddedSidedPoints {
                sidedPointsRelay.accept(embeddedSidedPoints)
            }
            return
        }

        debateNetworkService.makeRequest(with: .debate(primaryKey: debate.primaryKey))
            .map(Debate.self)
            .subscribe(onSuccess: { [weak self] debate in
                guard let sidedPoints = debate.sidedPoints,
                    let contextPoints = debate.contextPoints,
                    !sidedPoints.isEmpty else {
                        ErrorHandler.showBasicReportErrorBanner()
                        return
                }
                self?.sidedPointsRelay.accept(sidedPoints)
                self?.contextPointsDataSourceRelay.accept(contextPoints)
                self?.debate = debate
            }) { [weak self] error in
                self?.pointsRetrievalErrorRelay.accept(error)
            }.disposed(by: disposeBag)
    }

    func refreshSeenPoints() { seenPointsRelay.accept(UserDataManager.shared.getProgress(for: debate.primaryKey).seenPoints) }

}
