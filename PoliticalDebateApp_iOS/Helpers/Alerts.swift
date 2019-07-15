//
//  Alerts.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/22/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

public func safelyShowAlert(alert: UIAlertController) {
    if let appDelegate = AppDelegate.shared,
        let mainNavigationController = appDelegate.mainNavigationController,
        mainNavigationController.presentedViewController == nil {
        DispatchQueue.main.async(execute: {
            mainNavigationController.visibleViewController?.present(alert, animated: true, completion: nil)
        })
    }
}

public func showGeneralErrorAlert(_ message: String? = nil) {
    let errorAlert = UIAlertController(title: GeneralCopies.errorAlertTitle,
                                       message: message ?? GeneralError.basic.localizedDescription,
                                       preferredStyle: .alert)
    errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
    safelyShowAlert(alert: errorAlert)
}

public func showGeneralSuccessAlert(_ message: String) {
    let errorAlert = UIAlertController(title: GeneralCopies.successAlertTitle,
                                       message: message,
                                       preferredStyle: .alert)
    errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
    safelyShowAlert(alert: errorAlert)
}
