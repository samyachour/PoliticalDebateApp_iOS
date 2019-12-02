//
//  WKWebViewControllerFactory.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 10/29/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import WebKit

struct WKWebViewControllerFactory {
    private init() {}

    static func generateWKWebViewController(with url: URL) -> WKWebViewController {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return WKWebViewController(with: webView)
    }
}

class WKWebViewController: UIViewController {

    private let webView: WKWebView

    required init(with webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = webView
    }
}
