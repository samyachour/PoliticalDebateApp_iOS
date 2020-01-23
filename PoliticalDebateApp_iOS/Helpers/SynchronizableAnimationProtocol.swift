//
//  SynchronizableAnimationProtocol.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 12/7/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

/// When animation blocks need to be run directly after one another
/// without allowing properties to bleed into each other
protocol SynchronizableAnimation: NSObjectProtocol {
    var isExecutingAnimation: BehaviorRelay<Bool> { get } // initial value should be false
    var canExecuteAnimationSingle: Single<Void> { get }
    var disposeBag: DisposeBag { get }
    func executeSynchronousAnimation(_ block: @escaping (@escaping (Bool) -> Void) -> Void)
}

extension SynchronizableAnimation {
    var canExecuteAnimationSingle: Single<Void> {
        return isExecutingAnimation
            .filter({ !$0 })
            .take(1)
            .asSingle()
            .map({ _ in })
            .observeOn(MainScheduler.asyncInstance)
    }

    func executeSynchronousAnimation(_ block: @escaping (@escaping (Bool) -> Void) -> Void) {
        let fullAnimationBlock = { [weak self] in
            self?.isExecutingAnimation.accept(true)
            block({ _ in self?.isExecutingAnimation.accept(false)})
        }
        // If we're not currently executing an animation, run the animation block
        // If we are currently executing an animation, wait for the next time we can
        !isExecutingAnimation.value ? fullAnimationBlock() : canExecuteAnimationSingle.subscribe(onSuccess: { fullAnimationBlock() }).disposed(by: disposeBag)
    }
}
