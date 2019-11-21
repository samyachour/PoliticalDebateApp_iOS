//
//  UIFont+Custom.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

// swiftlint:disable force_unwrap

/// NOTE: Try printing UIFont.familyNames and then UIFont.fontNames(forFamilyname: "Family name") to see available file names
extension UIFont {
    static let standardSize: CGFloat = 18.0

    // These font files are hardcoded so they must exist
    static func primaryRegular(_ size: CGFloat = UIFont.standardSize) -> UIFont {
        return UIFont(name: "Roboto-Regular", size: size)!
    }
    static func primaryBold(_ size: CGFloat = UIFont.standardSize) -> UIFont {
        return UIFont(name: "Roboto-Bold", size: size)!
    }
    static func primaryLight(_ size: CGFloat = UIFont.standardSize) -> UIFont {
        return UIFont(name: "Roboto-Light", size: size)!
    }
    static func primaryLightItalic(_ size: CGFloat = UIFont.standardSize) -> UIFont {
        return UIFont(name: "Roboto-LightItalic", size: size)!
    }
}
