//
//  GeneralConstants.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

enum GeneralConstants {
    static let standardAnimationDuration = 0.4
    static let quickAnimationDuration = 0.1
    static let minimumPasswordLength = 6 // dictated by backend
    static let retryErrorCodes = [408, 502, 503, 504]
    static let maxAttemptCount = 3
    static let timeBetweenRetries = 1.0
    static let appBaseURL: String = {
        #if DEBUG
        return "https://politicaldebateapp-debug.herokuapp.com/api/"
        #else
        return "https://politicaldebateapp-prod.herokuapp.com/api/"
        #endif
    }()
}

enum GeneralColors {
    static let navBarTint = UIColor.customLightGreen1
    static let softButton = UIColor.customDarkGray1
    static let hardButton = UIColor.customDarkGray2
    static let background = UIColor.customOffWhite1
    static let navBarTitle = UIColor.black
    static let text = UIColor.black
    static let selected = UIColor.customOffWhite2
}

enum GeneralFonts {
    static let button = UIFont.primaryRegular()
    static let text = UIFont.primaryLight()
    static let navBarTitle = UIFont.primaryLight(24.0)
}

enum GeneralCopies {
    static let errorAlertTitle = "There was a problem"
    static let successAlertTitle = "Success"
    static let retryTitle = "Retry"
}

enum GeneralError: Error {
    case basic
    case retry
    case report
    case connectivity
    case alreadyHandled // For consumers to know if producers have already handled the error
    case refreshTokenExpired

    var localizedDescription: String {
        switch self {
        case .basic:
            return "Something weird happened."
        case .retry:
            return "Please try again."
        case .report:
            return "Please report this to the developer."
        case .connectivity:
            return "Having trouble connecting to the network."
        case .alreadyHandled:
            return "" // Never used in alerts
        case .refreshTokenExpired:
            return "You have been logged out."
        }
    }
}
