//
//  PointViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift

class PointViewModel {

    init(point: Point,
         debate: Debate) {
        self.point = point
        self.debate = debate
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    let point: Point
    let debate: Debate

    // MARK: - Observables

    let pointHandlingErrorRelay = PublishRelay<Error>()

    // MARK: - API calls

    private let progressNetworkService = NetworkService<ProgressAPI>()

    func markAsSeen() {
        let progress = UserDataManager.shared.getProgress(for: debate.primaryKey)
        guard !progress.seenPoints.contains(point.primaryKey) else { return }

        UserDataManager.shared.markProgress(progress,
                                            pointPrimaryKey: point.primaryKey,
                                            debatePrimaryKey: debate.primaryKey,
                                            totalPoints: debate.totalPoints)
            .subscribe { [weak self] (error) in
                self?.pointHandlingErrorRelay.accept(error)
            }.disposed(by: disposeBag)
    }

}
