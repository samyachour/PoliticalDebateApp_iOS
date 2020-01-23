//
//  BannerOnScreen
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

class BannerOnScreen {
    init(viewModel: NotificationBannerViewModel,
         view: NotificationBannerView) {
        self.viewModel = viewModel
        self.view = view
    }

    let viewModel: NotificationBannerViewModel
    let view: NotificationBannerView
    var timerDismissWorkItem: DispatchWorkItem?

    var topAnchor: NSLayoutConstraint?
    var bottomAnchor: NSLayoutConstraint?
}
