//
//  DebateCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class DebateCellViewModel {
    let debate: Debate
    let completedPercentage: Int
    var isStarred: Bool
    var starTintColor: UIColor {
        return isStarred ? .customLightGreen2 : .customLightGray1
    }

    init(debate: Debate, completedPercentage: Int, isStarred: Bool) {
        self.debate = debate
        self.completedPercentage = completedPercentage
        self.isStarred = isStarred
    }

    func starOrUnstarDebate() -> Single<Response?> {
        return UserDataManager.shared.starOrUnstarDebate(debate.primaryKey, unstar: isStarred) // if the current state is starred and the user taps it, then we're unstarring
            .do(onSuccess: { [weak self] _ in
                if let isStarred = self?.isStarred {
                    self?.isStarred = !isStarred
                }
        })
    }
}
