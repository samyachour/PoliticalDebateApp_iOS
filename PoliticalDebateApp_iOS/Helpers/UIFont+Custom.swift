//
//  UIFont+Custom.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

public extension UIFont {
    static let standardSize: CGFloat = 16.0

    static func primaryLight(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Light", size: size)
    }
    static func primaryRegular(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Regular", size: size)
    }
    static func primaryBold(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Bold", size: size)
    }
    static func primaryThin(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Thin", size: size)
    }
    static func primaryMedium(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Medium", size: size)
    }
    static func primarySemibold(_ size: CGFloat = UIFont.standardSize) -> UIFont? {
        return UIFont(name: "Manrope-Semibold", size: size)
    }
}
