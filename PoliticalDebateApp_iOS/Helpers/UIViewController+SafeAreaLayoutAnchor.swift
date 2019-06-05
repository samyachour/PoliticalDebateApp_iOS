//
//  UIViewController+SafeAreaLayoutAnchor.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

extension UIViewController {
    public var topLayoutAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return view.topLayoutAnchor
        } else {
            return topLayoutGuide.bottomAnchor
        }
    }

    public var bottomLayoutAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return view.bottomLayoutAnchor
        } else {
            return bottomLayoutGuide.topAnchor
        }
    }
}
