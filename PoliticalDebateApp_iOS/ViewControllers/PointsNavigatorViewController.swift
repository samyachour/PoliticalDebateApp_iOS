//
//  PointsNavigatorViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class PointsNavigatorViewController: UIViewController {

    required init(viewModel: PointsNavigatorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil) // we don't use nibs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        installViewBinds()
        installViewConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        markAsSeen()
    }

    // MARK: - Observers & Observables

    private let viewModel: PointsNavigatorViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    private var pointsTableViewHeightAnchor: NSLayoutConstraint?
    private static let inset: CGFloat = 16.0

    // MARK: - UI Elements

    private lazy var descriptionTextView = BasicUIElementFactory.generateDescriptionTextView(MarkDownFormatter.format(viewModel.point.description,
                                                                                                                      with: [.font: GeneralFonts.text,
                                                                                                                             .foregroundColor: GeneralColors.text],
                                                                                                                      hyperlinks: viewModel.point.hyperlinks))

    private lazy var pointsTableViewController = PointsTableViewController(viewModel: PointsTableViewModel(debate: viewModel.debate,
                                                                                                           viewState: .embeddedRebuttals,
                                                                                                           embeddedSidedPoints: viewModel.point.rebuttals))
}

// MARK: - View constraints & binding
extension PointsNavigatorViewController {

    // MARK: View constraints

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background

        view.addSubview(descriptionTextView)
        addChild(pointsTableViewController)
        view.addSubview(pointsTableViewController.view)

        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        pointsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false

        descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PointsNavigatorViewController.inset).isActive = true
        descriptionTextView.topAnchor.constraint(equalTo: topLayoutAnchor, constant: PointsNavigatorViewController.inset).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PointsNavigatorViewController.inset).isActive = true

        pointsTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pointsTableViewController.view.topAnchor.constraint(greaterThanOrEqualTo: descriptionTextView.bottomAnchor).isActive = true
        pointsTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pointsTableViewController.view.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        // Set the height to the entire screen initially so the tableView.visibleCells property will include
        // all the cells and we can accurately recompute the necessary height
        pointsTableViewHeightAnchor = pointsTableViewController.view.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).injectPriority(.required - 1)
        pointsTableViewHeightAnchor?.isActive = true
        pointsTableViewController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pointsTableViewHeightAnchor?.constant = pointsTableViewController.pointsTableViewHeight
    }

    // MARK: View binding

    private func installViewBinds() {
        descriptionTextView.delegate = self
    }

    private func markAsSeen() {
        viewModel.markAsSeen()?.subscribe(onError: { error in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard let moyaError = error as? MoyaError,
                let response = moyaError.response else {
                    ErrorHandlerService.showBasicRetryErrorBanner()
                    return
            }

            switch response.statusCode {
            case 404:
                ErrorHandlerService.showBasicReportErrorBanner()
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }).disposed(by: disposeBag)
    }
}

// MARK: - UITextViewDelegate
extension PointsNavigatorViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        navigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}
