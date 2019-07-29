//
//  Constants.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

enum Constants {
    static let standardAnimationDuration = 0.4
    static let minimumPasswordLength = 6 // dictated by backend
    static let retryErrorCodes = [408, 502, 503, 504]
    static let customBackendErrorMessageCode = 400
    static let maxAttemptCount = 3
    static let timeBetweenRetries = 1.0
}

enum GeneralColors {
    static let navBarTint = UIColor.customLightGreen1
    static let softButton = UIColor.customDarkGray1
    static let hardButton = UIColor.customDarkGray2
    static let background = UIColor.customOffWhite1
    static let navBarTitle = UIColor.black
    static let text = UIColor.black
}

enum GeneralFonts {
    static let button = UIFont.primaryRegular()
    static let navBarTitle = UIFont.primaryLight(24.0)
}

enum GeneralCopies {
    static let errorAlertTitle = "There was a problem"
    static let successAlertTitle = "Success"
}

enum GeneralError: Error {
    case basic
    case unknownSuccessCode // not 200-399 but not the success code we expected
    case unknownErrorCode // 400+ but not the error code we expected
    case connectivity
    case alreadyHandled // For consumers to know if producers have already handled the error
    case refreshTokenExpired

    var localizedDescription: String {
        switch self {
        case .basic:
            return "Something weird happened. Please try again."
        case .unknownSuccessCode:
            return "Something weird happened. Your request completed successfully though. Please report this to the developer."
        case .unknownErrorCode:
            return "Something weird happened. Your request failed in an unexpected way. Please report this to the developer."
        case .connectivity:
            return "Having trouble connecting to the network."
        case .alreadyHandled:
            return "" // Never used in alerts
        case .refreshTokenExpired:
            return "You have been logged out."
        }
    }
}

enum GeneralKeys {
    static let message = "message" // key from backend custom error message
}
