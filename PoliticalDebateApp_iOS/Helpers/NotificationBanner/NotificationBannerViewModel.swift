//
//  NotificationBannerViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

struct NotificationBannerViewModel {

    init(style: NotificationBannerStyle,
         title: String,
         subtitle: String? = nil,
         duration: Duration? = nil,
         buttonConfig: ButtonConfiguration? = nil,
         iconConfig: IconConfiguration? = nil,
         bannerCanBeDismissed: Bool? = nil,
         bannerWasDismissedAutomatically: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.duration = duration ?? style.defaultDuration
        self.foregroundColor = style.defaultForegroundColor
        self.backgroundColor = style.defaultBackgroundColor
        self.buttonConfig = buttonConfig ?? style.defaultButtonConfig
        self.iconConfig = iconConfig ?? style.defaultIconConfig
        self.bannerCanBeDismissed = bannerCanBeDismissed ?? style.defaultBannerCanBeDismissed
        self.bannerWasDismissedAutomatically = bannerWasDismissedAutomatically ?? style.defaultBannerWasDismissedAutomatically
    }

    let title: String
    let subtitle: String?
    let duration: Duration
    let foregroundColor: UIColor
    let backgroundColor: UIColor
    let buttonConfig: ButtonConfiguration
    let iconConfig: IconConfiguration
    let bannerCanBeDismissed: Bool
    let bannerWasDismissedAutomatically: (() -> Void)
    let identifier = UUID()

    enum NotificationBannerStyle: Int {
        case info
        case success
        case error

        var defaultDuration: NotificationBannerViewModel.Duration {
            switch self {
            case .error:
                return .seconds(seconds: 5.0)
            case .info,
                 .success:
                return .defaultValue
            }
        }

        var defaultForegroundColor: UIColor {
            switch self {
            case .info,
                 .success,
                 .error:
                return .customOffWhite1
            }
        }

        var defaultBackgroundColor: UIColor {
            switch self {
            case .info:
                return .bannerBlue
            case .success:
                return .bannerGreen
            case .error:
                return .bannerRed
            }
        }

        var defaultButtonConfig: NotificationBannerViewModel.ButtonConfiguration {
            switch self {
            case .info,
                 .success,
                 .error:
                return .customTitle(title: "Dismiss", action: nil)
            }
        }

        var defaultIconConfig: NotificationBannerViewModel.IconConfiguration {
            switch self {
            case .info,
                 .success,
                 .error:
                return .none
            }
        }

        var defaultBannerCanBeDismissed: Bool {
            switch self {
            case .info,
                 .success,
                 .error:
                return true
            }
        }

        var defaultBannerWasDismissedAutomatically: () -> Void {
            return { return } // empty closure
        }
    }

    enum Duration {
        case defaultValue
        case forever
        case seconds(seconds: TimeInterval)
    }

    enum ButtonConfiguration {
        case customTitle(title: String, action: (()->Void)?)
        case customImage(image: UIImage, action: (()->Void)?)
    }

    enum IconConfiguration {
        case none
        case customIcon(iconImage: UIImage?)
    }
}

extension NotificationBannerViewModel: Equatable {
    static func == (lhs: NotificationBannerViewModel, rhs: NotificationBannerViewModel) -> Bool {
        // Banners w/ the same text and color but different durations or button/icon configs are still too similar
        return lhs.foregroundColor == rhs.foregroundColor &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle
    }
}
