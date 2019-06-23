//
//  SafelyShowAlert.swift
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
