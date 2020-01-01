//
//  UIView+SafeAreaLayoutAnchor.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

extension UIView {
    var topLayoutAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) { return safeAreaLayoutGuide.topAnchor }
        return topAnchor
    }

    var bottomLayoutAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) { return safeAreaLayoutGuide.bottomAnchor }
        return bottomAnchor
    }

    var centerXLayoutAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) { return safeAreaLayoutGuide.centerXAnchor }
        return centerXAnchor
    }

    var centerYLayoutAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) { return safeAreaLayoutGuide.centerYAnchor }
        return centerYAnchor
    }
}
