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
    // MARK: - Datasource

    let pointsViewModelRelay = BehaviorRelay<[PointTableViewCellViewModel]>(value: [])
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    let pointsRetrievalErrorRelay = PublishRelay<Error>()

    // MARK: - Input handling

    private let disposeBag = DisposeBag()

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

}
