//
//  PointsNavigatorViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class PointsNavigatorViewModel {

    init(point: Point,
         debate: Debate) {
        self.point = point
        self.debate = debate
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    let point: Point
    let debate: Debate

    // MARK: - API calls

    private let progressNetworkService = NetworkService<ProgressAPI>()

    func markAsSeen() -> Single<Response?>? {
        return UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                                   debatePrimaryKey: debate.primaryKey,
                                                   totalPoints: debate.totalPoints)
    }

}
