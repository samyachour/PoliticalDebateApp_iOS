//
//  NotificationBannerQueue.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

class NotificationBannerQueue {

    static let shared = NotificationBannerQueue()
    typealias NotificationBannerID = UUID

    @discardableResult func enqueueBanner(using viewModel: NotificationBannerViewModel) -> NotificationBannerID? {
        // Don't want the user to see duplicate banners
        guard !bannersToShow.contains(viewModel) else { return nil }
        bannersToShow.append(viewModel)
        return viewModel.identifier
    }

    func removeBannerFromQueue(by bannerID: NotificationBannerID) {
        DispatchQueue.main.async {
            if let currentBannerOnScreen = self.currentBannerOnScreen {
                if bannerID == currentBannerOnScreen.viewModel.identifier {
                    self.dismiss(currentBannerOnScreen, automatic: false)
                } else if let index = self.bannersToShow.firstIndex(where: { $0.identifier == bannerID }) {
                    self.bannersToShow.remove(at: index)
                }
            }
        }
    }

    func removeAllBannersFromQueue() {
        DispatchQueue.main.async {
            if let currentBannerOnScreen = self.currentBannerOnScreen {
                self.dismiss(currentBannerOnScreen)
            }
            self.bannersToShow.removeAll()
        }
    }

    // MARK: - Private methods

    private func show(_ bannerOnScreen: BannerOnScreen) {
        let timeOnScreen: TimeInterval

        switch bannerOnScreen.viewModel.duration {
        case .defaultValue:
            timeOnScreen = 3.0
        case .forever:
            timeOnScreen = TimeInterval.infinity
        case .seconds(let second):
            timeOnScreen = second
        }

        DispatchQueue.main.async {
            self.installBannerViewConstraint(bannerOnScreen)
            self.mainWindow?.layoutIfNeeded()

            UIView.animate(withDuration: 0.35,
                           delay: 0,
                           options: [.curveEaseInOut, .allowUserInteraction],
                           animations: {
                            self.showBanner(bannerOnScreen)
                            self.mainWindow?.layoutIfNeeded()
            }, completion: { (_) in
                if let dispatchWork = bannerOnScreen.timerDismissWorkItem {
                    DispatchQueue.main.asyncAfter(deadline: .now()+timeOnScreen, execute: dispatchWork)
                }
            })
        }
    }

    private func dismiss(_ bannerOnScreen: BannerOnScreen, automatic: Bool = true) {
        bannerOnScreen.timerDismissWorkItem?.cancel()

        mainWindow?.layoutIfNeeded()

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.35,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                            self.hideBanner(bannerOnScreen)
                            self.mainWindow?.layoutIfNeeded()
            }) { (_) in
                if automatic { bannerOnScreen.viewModel.bannerWasDismissedAutomatically() }
                bannerOnScreen.view.removeFromSuperview()

                self.currentBannerOnScreen = nil
                self.addNextBannerIfNeeded()
            }
        }
    }

    private func installBannerViewConstraint(_ bannerOnScreen: BannerOnScreen) {
        if let mainWindow = mainWindow {
            mainWindow.addSubview(bannerOnScreen.view)

            bannerOnScreen.view.translatesAutoresizingMaskIntoConstraints = false

            bannerOnScreen.view.leadingAnchor.constraint(equalTo: mainWindow.leadingAnchor).isActive = true
            bannerOnScreen.view.trailingAnchor.constraint(equalTo: mainWindow.trailingAnchor).isActive = true

            bannerOnScreen.topAnchor = bannerOnScreen.view.topAnchor.constraint(equalTo: mainWindow.topAnchor)
            bannerOnScreen.bottomAnchor = bannerOnScreen.view.bottomAnchor.constraint(equalTo: mainWindow.topAnchor)
            hideBanner(bannerOnScreen)
        }
    }

    private func showBanner(_ bannerOnScreen: BannerOnScreen) {
        bannerOnScreen.bottomAnchor?.isActive = false
        bannerOnScreen.topAnchor?.isActive = true
    }

    private func hideBanner(_ bannerOnScreen: BannerOnScreen) {
        bannerOnScreen.topAnchor?.isActive = false
        bannerOnScreen.bottomAnchor?.isActive = true
    }

    private func addNextBannerIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
            !self.bannersToShow.isEmpty,
            self.currentBannerOnScreen == nil else {
                return
            }
            let viewModel = self.bannersToShow.removeFirst()

            let nextBannerOnScreen = BannerOnScreen(viewModel: viewModel,
                                                    view: self.getBannerView(viewModel))

            if viewModel.bannerCanBeDismissed {
                nextBannerOnScreen.timerDismissWorkItem = DispatchWorkItem(block: {
                    self.dismiss(nextBannerOnScreen)
                })
            }

            self.currentBannerOnScreen = nextBannerOnScreen
            self.show(nextBannerOnScreen)
        }
    }

    private func getBannerView(_ viewModel: NotificationBannerViewModel) -> NotificationBannerView {

        let button = { () -> UIButton? in
            let button: UIButton?
            switch viewModel.buttonConfig {
            case .customTitle(let title, _):
                button = buildButton(viewModel)
                button?.setTitle(title, for: .normal)
            case .customImage(let image, _):
                button = buildButton(viewModel)
                button?.setImage(image, for: .normal)
            }
            return button
        }()

        let iconImage = { () -> UIImage? in
            switch viewModel.iconConfig {
            case .none:
                return nil
            case let .customIcon(iconImage):
                return iconImage
            }
        }()

        let view = NotificationBannerView(title: viewModel.title,
                                          subtitle: viewModel.subtitle,
                                          button: button,
                                          image: iconImage,
                                          viewModel: viewModel)

        view.backgroundColor = viewModel.backgroundColor

        return view
    }

    private func buildButton(_ viewModel: NotificationBannerViewModel) -> UIButton? {
        let button: ButtonWithActionClosure?
        switch viewModel.buttonConfig {
        case .customTitle(_, let action),
             .customImage(_, let action):
            button = ButtonWithActionClosure(action: { [weak self] in
                action?()
                self?.dismissAction()
            })
        }

        button?.titleLabel?.font = .primaryBold(16)
        button?.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button?.setTitleColor(viewModel.foregroundColor, for: .normal)

        return button
    }

    private func dismissAction() {
        if let currentBannerOnScreen = currentBannerOnScreen { // only the dismiss button on the top-most banner is tappable
            removeBannerFromQueue(by: currentBannerOnScreen.viewModel.identifier)
        }
    }

    // MARK: - Private properties

    private var _bannersToShow = [NotificationBannerViewModel]()
    private var bannersToShow: [NotificationBannerViewModel] {
        set {
            bannerQueue.sync(flags: .barrier) { () -> Void in
                _bannersToShow = newValue
            }
            addNextBannerIfNeeded()
        }
        get {
            return bannerQueue.sync { () -> [NotificationBannerViewModel] in
                _bannersToShow
            }
        }
    }

    private let bannerQueue = DispatchQueue(label: "NotificationBannerQueue", attributes: .concurrent)
    private var currentBannerOnScreen: BannerOnScreen?
    private let mainWindow = UIApplication.shared.keyWindow
}
