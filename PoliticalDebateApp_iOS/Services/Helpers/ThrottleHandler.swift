//
//  ThrottleHandler.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

public class ThrottleHandler {
    public static let checkForThrottle = { (error: Error) -> Void in
        if let moyaError = error as? MoyaError,
            let response = moyaError.response,
            response.statusCode == 429 {
            ThrottleHandler.showThrottleAlert(with: response)
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

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let mainNavigationController = appDelegate.mainNavigationController,
            mainNavigationController.presentedViewController == nil {
            mainNavigationController.visibleViewController?.present(throttleAlert, animated: true, completion: nil)
        }
    }
}
