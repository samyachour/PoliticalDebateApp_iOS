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

class WKWebViewController: UIViewController, WKNavigationDelegate {

    // MARK: UI Elements

    private let webView: WKWebView

    private lazy var loadingIndicator = BasicUIElementFactory.generateLoadingIndicator()

    // MARK: Init

    required init(with webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        installViewConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View constraints

    override func loadView() {
        self.view = webView
    }

    private func installViewConstraints() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.startAnimating()
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

}
