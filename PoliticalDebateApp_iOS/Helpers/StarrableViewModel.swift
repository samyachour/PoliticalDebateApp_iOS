//
//  StarrableViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/8/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import Moya
import RxCocoa
import RxSwift
import UIKit

protocol StarrableViewModel: AnyObject {
    var debate: Debate { get }
    var isStarred: Bool { get set }
    var starTintColor: UIColor { get }
    func starOrUnstarDebate() -> Single<Response?>
}

extension StarrableViewModel {
    var starTintColor: UIColor {
        return isStarred ? GeneralColors.starredTint : GeneralColors.unstarredTint
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
