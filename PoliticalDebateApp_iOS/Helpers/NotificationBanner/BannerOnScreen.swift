//
//  BannerOnScreen
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

struct BannerOnScreen {

    init(viewModel: NotificationBannerViewModel,
         view: NotificationBannerView,
         timerDismissWorkItem: DispatchWorkItem? = nil) {
        self.viewModel = viewModel
        self.view = view
        self.timerDismissWorkItem = timerDismissWorkItem
    }

    let viewModel: NotificationBannerViewModel
    let view: NotificationBannerView
    let timerDismissWorkItem: DispatchWorkItem?
}
