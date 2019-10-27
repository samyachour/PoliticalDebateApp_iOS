//
//  DebateCollectionViewCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class DebateCollectionViewCellViewModel: StarrableViewModel {
    let debate: Debate
    var completedPercentage: Int
    var isStarred: Bool
    let disposeBag = DisposeBag()

    init(debate: Debate, completedPercentage: Int, isStarred: Bool) {
        self.debate = debate
        self.completedPercentage = completedPercentage
        self.isStarred = isStarred
    }
}
