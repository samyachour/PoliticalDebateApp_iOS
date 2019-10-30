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

    init(rootPoint: Point,
         debate: Debate) {
        self.rootPoint = rootPoint
        self.debate = debate
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    let rootPoint: Point
    let debate: Debate

}
