//
//  ErrorHandler.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/5/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class ErrorHandler {

    // MARK: - Basic errors

    // For observable onError closures
    static let handleErrorAlertClosure: (Error) -> Void = { error in
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: error.localizedDescription))
    }

    static func showBasicErrorBanner() {
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: GeneralError.basic.localizedDescription))
    }

    static func showBackendErrorMessage(_ response: Response) {
        guard response.statusCode == Constants.customBackendErrorMessageCode,
            let responseJSONData = try? response.mapJSON(failsOnEmptyData: true),
            let responseJSON = responseJSONData as? [String: AnyObject],
            let customBackendErrorMessage = responseJSON[GeneralKeys.message] as? String else {
                return
        }

        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: customBackendErrorMessage))
    }

    static let shouldRetryRequest = { (error: Observable<Error>) -> Observable<Void> in
        error.enumerated().flatMap { (index, error) -> Observable<Void> in
            guard let moyaError = error as? MoyaError,
                let errorCode = moyaError.response?.statusCode,
                Constants.retryErrorCodes.contains(errorCode),
                index <= Constants.maxAttemptCount else {
                    return .error(error) // Pass the error along
            }

            Thread.sleep(forTimeInterval: Constants.timeBetweenRetries)
            return .just(())
        }
    }

    // MARK: - Connectivity errors

    static let checkForConnectivityError = { (error: Error) -> Void in
        if let error = error as? MoyaError {
            switch error {
            case .underlying(let error, _): // Access underlying swift error, see MoyaError.swift
                if (error as NSError).domain == NSURLErrorDomain {
                    NotificationBannerQueue.shared
                        .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                          title: GeneralError.connectivity.localizedDescription))
                    throw GeneralError.alreadyHandled // so consumer knows
                }
            default:
                break
            }
        }
    }

    // MARK: - Throttle errors

    static let checkForThrottleError = { (error: Error) -> Void in
        if let moyaError = error as? MoyaError,
            let response = moyaError.response,
            response.statusCode == 429 {
            ErrorHandler.showThrottleAlert(with: response)
            throw GeneralError.alreadyHandled // so consumer knows
        }
    }

    private static func showThrottleAlert(with response: Response) {
        guard let responseBody = try? response.mapJSON(),
            let responseDict = responseBody as? [AnyHashable: String],
            let responseString = responseDict["detail"],
            let durationRange = responseString.range(of: "available in ") else {
                return
        }

        let timeRemaining = responseString[durationRange.upperBound...]

        let throttleAlert = UIAlertController(title: "You are doing that too much",
                                              message: "Please try again in \(timeRemaining)",
                                              preferredStyle: .alert)
        throttleAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: throttleAlert)
    }
}
