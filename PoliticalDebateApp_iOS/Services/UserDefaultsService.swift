//
//  UserDefaultsService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/8/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

struct UserDefaultsService {

    private init() {}

    private static let userDefaults = UserDefaults.standard

    // MARK: - UserDefaults properties

    static var hasSeenRegisterInfoAlert: Bool {
        get { return userDefaults.bool(forKey: UserDefaultsKeys.hasSeenRegisterInfoAlert.rawValue) }
        set { userDefaults.set(newValue, forKey: UserDefaultsKeys.hasSeenRegisterInfoAlert.rawValue) }
    }
}

private enum UserDefaultsKeys: String {
    case hasSeenRegisterInfoAlert
}
