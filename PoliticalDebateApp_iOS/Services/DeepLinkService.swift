//
//  DeepLinkService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

enum UrlHosts: String {
    case debate
}

struct DeepLinkService {

    private init() {}

    enum Constants {
        static let appNameSpace = "com.PoliticalDebateApp"
        static let primaryKeyKey = "primaryKey"
    }

    static func handle(_ url: URL) {
        guard let scheme = url.scheme,
            scheme.localizedCaseInsensitiveCompare(Constants.appNameSpace) == .orderedSame,
            let host = url.host,
            let localHost = UrlHosts(rawValue: host.lowercased()) else {
                return
        }

        var parameters: [String: String] = [:]
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
            parameters[$0.name] = $0.value
        }

        switch localHost {
        case .debate:
            openDebate(with: parameters)
        }
    }

    private static let debateNetworkService = NetworkService<DebateAPI>()

    static func openDebate(with parameters: [String: String]) {
        guard let primaryKeyString = parameters[Constants.primaryKeyKey],
            let primaryKey = Int(primaryKeyString) else {
                return
        }

        // static class, no need for disposal
        _ = debateNetworkService.makeRequest(with: .debate(primaryKey: primaryKey))
            .map(Debate.self)
            .subscribe(onSuccess: { debate in
                let pointsTableViewModel = PointsTableViewModel(debate: debate,
                                                                isStarred: UserDataManager.shared.isStarred(debate.primaryKey),
                                                                viewState: .standaloneRootPoints)
                let pointsTableViewController = PointsTableViewController(viewModel: pointsTableViewModel)
                AppDelegate.shared?.mainNavigationController?.pushViewController(pointsTableViewController, animated: true)
            }) { error in
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Could not open debate."))
        }
    }
}
