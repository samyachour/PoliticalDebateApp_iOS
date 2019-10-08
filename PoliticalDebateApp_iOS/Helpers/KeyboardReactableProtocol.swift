//
//  KeyboardReactableProtocol.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

protocol KeyboardReactable {
    var activeTextField: UITextField? { get }
    var scrollViewContainer: UIScrollView { get }
    var disposeBag: DisposeBag { get } // for NotificationCenter subscription
}

extension KeyboardReactable where Self: UIViewController {
    func installKeyboardShiftingObserver() {
        let keyboardWillShowProducer = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
        let keyboardWillHideProducer = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        let latestYOffsetRelay = BehaviorRelay<CGFloat>(value: 0.0) // store offset to undo when keyboard hides

        Observable.merge([keyboardWillShowProducer, keyboardWillHideProducer])
            .withLatestFrom(latestYOffsetRelay, resultSelector: { notification, latestYOffsetValue in (notification, latestYOffsetValue)})
            .subscribe(onNext: { [weak self] (notification, latestYOffsetValue) in
                guard self?.view.window != nil else { // make sure view is onscreen
                        return
                }

                if notification.name == UIResponder.keyboardWillShowNotification {
                    guard let activeTextField = self?.activeTextField,
                        let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                        let textFieldAbsoluteFrame = activeTextField.superview?.convert(activeTextField.frame, to: nil),
                        // Make sure keyboard will cover up our activeTextField
                        keyboardValue.cgRectValue.minY < textFieldAbsoluteFrame.maxY else {
                            return
                    }
                    // Get the distance between the top of the keyboard and the bottom of our activeTextField
                    let textFieldToKeyboardOffset = textFieldAbsoluteFrame.maxY - keyboardValue.cgRectValue.minY

                    self?.scrollViewContainer.contentOffset.y += textFieldToKeyboardOffset
                    latestYOffsetRelay.accept(textFieldToKeyboardOffset)
                } else {
                    self?.scrollViewContainer.contentOffset.y -= latestYOffsetValue
                    latestYOffsetRelay.accept(0.0)
                }
            }).disposed(by: disposeBag)
    }

    func installHideKeyboardTapGesture() {
        let tapGesture = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.subscribe { [weak self] (_) in
            self?.activeTextField?.resignFirstResponder()
        }.disposed(by: disposeBag)
    }
}
