//
//  ErrorHandlerService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/5/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

struct ErrorHandlerService {

    private init() {}

    // MARK: - Basic errors

    static func showBasicRetryErrorBanner(_ buttonAction: (() -> Void)? = nil) {
        guard let buttonAction = buttonAction else {
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: GeneralError.basic.localizedDescription,
                                                                                            subtitle: GeneralError.retry.localizedDescription))
            return
        }

        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: GeneralError.basic.localizedDescription,
                                                                                        subtitle: GeneralError.retry.localizedDescription,
                                                                                        buttonConfig: .customTitle(title: GeneralCopies.retryTitle,
                                                                                                                   action: buttonAction)))
    }

    static func showBasicReportErrorBanner(_ title: String = GeneralError.basic.localizedDescription) {
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: title,
                                                                                        subtitle: GeneralError.report.localizedDescription))
    }

    static func showBadRequestError(from response: Response) {
        switch response.statusCode {
        case GeneralConstants.customErrorCode:
            if let backendErrorMessage = try? JSONDecoder().decode(BackendErrorMessage.self, from: response.data) {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: backendErrorMessage.messageString))
            } else {
                ErrorHandlerService.showBasicReportErrorBanner()
            }
        default:
            ErrorHandlerService.showBasicRetryErrorBanner()
        }
    }

    // MARK: - Email/Password errors

    static func showInvalidEmailError() {
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: "Please provide a proper email"))
    }

    static func showInvalidPasswordError() {
        NotificationBannerQueue.shared
            .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                              title: "Your password must be at least \(GeneralConstants.minimumPasswordLength) characters."))
    }

    static func showInvalidPasswordMatchError() {
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: "Passwords do not match."))
    }

    // MARK: - Connectivity errors

    static func checkForConnectivityError(error: Observable<Error>) -> Observable<Void> {
        return error.enumerated().flatMap { (_, error) -> Observable<Void> in
            guard let moyaError = error as? MoyaError,
                moyaError.errorCode == 6 else {
                    return .error(error) // Pass the error along
            }

            return Observable<Void>.create({ observer in
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                      title: GeneralError.connectivity.localizedDescription,
                                                                      buttonConfig: NotificationBannerViewModel.ButtonConfiguration
                                                                        .customTitle(title: GeneralCopies.retryTitle, action: {
                                                                            observer.onNext(())
                                                                        }),
                                                                      bannerWasIgnored: {
                                                                        observer.onError(GeneralError.alreadyHandled)
                    }))
                return Disposables.create()
            })
        }
    }

    // MARK: - Throttle errors

    static func checkForThrottleError(error: Error) -> Single<Response> {
        guard let moyaError = error as? MoyaError,
            let response = moyaError.response,
            response.statusCode == 429 else {
                return .error(error) // Pass the error along
        }

        ErrorHandlerService.showThrottleAlert(with: response)
        return .error(GeneralError.alreadyHandled) // so consumer knows
    }

    private static func showThrottleAlert(with response: Response) {
        guard let responseBody = try? response.mapJSON(),
            let responseDict = responseBody as? [AnyHashable: String],
            let responseString = responseDict["detail"],
            let durationRangeStart = responseString.range(of: "available in "),
            let durationRangeEnd = responseString.range(of: " seconds"),
            let timeRemaining = Int(responseString[durationRangeStart.upperBound..<durationRangeEnd.lowerBound]) else {
                return
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        guard let timeRemainingFormatted = formatter.string(from: TimeInterval(timeRemaining)) else { return }

        let throttleAlert = UIAlertController(title: "You are doing that too much",
                                              message: "Please try again in \(timeRemainingFormatted)",
                                              preferredStyle: .alert)
        throttleAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: throttleAlert)
    }

}
