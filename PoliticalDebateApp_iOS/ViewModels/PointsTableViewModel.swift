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

class PointsTableViewModel {

    init(debate: Debate) {
        fullDebateRelay = BehaviorRelay<Debate>(value: debate)
        subscribeToSeenPointsAndDebateUpdates()
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    private let pointsDataSourceRelay = BehaviorRelay<[PointTableViewCellViewModel]>(value: [])
    lazy var sharedPointsDataSourceRelay = pointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    let pointsRetrievalErrorRelay = PublishRelay<Error>()

    private let seenPointsRelay = BehaviorRelay<[PrimaryKey]>(value: [])

    // Full debate as opposed to the stripped debate objects
    // that the debates collection view uses
    private let fullDebateRelay: BehaviorRelay<Debate>
    lazy var debateTitleRelay = fullDebateRelay.map({ return $0.shortTitle })
    private var debatePrimaryKey: PrimaryKey {
        return fullDebateRelay.value.primaryKey
    }

    private func subscribeToSeenPointsAndDebateUpdates() {
        BehaviorRelay.combineLatest(seenPointsRelay, fullDebateRelay) { return ($0, $1) }
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                let seenPointsMatch = lhs.0 == rhs.0
                let debatesMatch = lhs.1.primaryKey == rhs.1.primaryKey &&
                    lhs.1.debateMap?.count ?? 0 == rhs.1.debateMap?.count ?? 0

                return seenPointsMatch && debatesMatch
            }.subscribe { [weak self] latestPointsEvent in
                guard let seenPoints = latestPointsEvent.element?.0,
                    let debate = latestPointsEvent.element?.1,
                    let debatePoints = debate.debateMap else {
                        return
                }

                self?.pointsDataSourceRelay.accept(debatePoints.map({ PointTableViewCellViewModel(point: $0,
                                                                                                  debatePrimaryKey: debate.primaryKey,
                                                                                                  seenPoints: seenPoints) }))
        }.disposed(by: disposeBag)
    }

    // MARK: - API calls

    private let progressNetworkService = NetworkService<ProgressAPI>()

    func refreshSeenPoints() { seenPointsRelay.accept(UserDataManager.shared.currentSeenPoints) }

    func retrieveSeenPoints() {
        UserDataManager.shared.getProgress(for: debatePrimaryKey)
            .subscribe(onSuccess: { [weak self] progress in
                guard let seenPoints = progress.seenPoints else { return }

                self?.seenPointsRelay.accept(seenPoints)
            }) { [weak self] error in
                self?.pointsRetrievalErrorRelay.accept(error)
            }.disposed(by: disposeBag)
    }

    private let debateNetworkService = NetworkService<DebateAPI>()

    func retrieveFullDebate() {
        debateNetworkService.makeRequest(with: .debate(primaryKey: debatePrimaryKey))
            .map(Debate.self)
            .subscribe(onSuccess: { [weak self] debate in
                self?.fullDebateRelay.accept(debate)
            }) { [weak self] error in
                self?.pointsRetrievalErrorRelay.accept(error)
        }.disposed(by: disposeBag)
    }
}
