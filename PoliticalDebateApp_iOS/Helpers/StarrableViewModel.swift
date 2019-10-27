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
    var disposeBag: DisposeBag { get }
    var debate: Debate { get }
    var isStarred: Bool { get set }
    var starTintColor: UIColor { get }
    func starOrUnstarDebate() -> Single<Response?>
}

extension StarrableViewModel {
    var starTintColor: UIColor {
        return isStarred ? .customLightGreen2 : .customLightGray1
    }

    func starOrUnstarDebate() -> Single<Response?> {
        let starredRequest = UserDataManager.shared.starOrUnstarDebate(debate.primaryKey, unstar: isStarred) // if the current state is starred and the user taps it, then we're unstarring

        starredRequest.subscribe(onSuccess: { [weak self] _ in
            if let isStarred = self?.isStarred {
                self?.isStarred = !isStarred
            }
        }).disposed(by: disposeBag)

        return starredRequest
    }
}
