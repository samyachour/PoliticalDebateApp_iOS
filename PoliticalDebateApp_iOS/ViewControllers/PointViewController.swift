//
//  PointViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class PointViewController: UIViewController {

    required init(viewModel: PointViewModel) {
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

        viewModel.markAsSeen()

        UIView.animate(withDuration: Constants.standardAnimationDuration) { [weak self] in
            self?.navigationController?.navigationBar.barTintColor = self?.viewModel.point.side?.color
            self?.navigationController?.navigationBar.layoutIfNeeded()
        }
    }

    // MARK: - Observers & Observables

    private let viewModel: PointViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    private var pointsTableViewHeightAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var descriptionTextView: UITextView = {
        let descriptionTextView = UITextView(frame: .zero)
        descriptionTextView.isEditable = false
        descriptionTextView.dataDetectorTypes = .link
        descriptionTextView.isUserInteractionEnabled = true
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.backgroundColor = .clear
        return descriptionTextView
    }()

    private lazy var pointsTableViewController = PointsTableViewController(viewModel: PointsTableViewModel(debate: viewModel.debate,
                                                                                                           viewState: .embeddedRebuttals,
                                                                                                           rebuttals: viewModel.point.rebuttals))
}

// MARK: - View constraints & binding
extension PointViewController: UITextViewDelegate {

    // MARK: View constraints

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background

        view.addSubview(descriptionTextView)
        addChild(pointsTableViewController)
        view.addSubview(pointsTableViewController.view)

        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        pointsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false

        descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        descriptionTextView.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        pointsTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pointsTableViewController.view.topAnchor.constraint(greaterThanOrEqualTo: descriptionTextView.bottomAnchor).isActive = true
        pointsTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pointsTableViewController.view.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        pointsTableViewHeightAnchor = pointsTableViewController.view.heightAnchor.constraint(equalToConstant: 0.0).injectPriority(.required - 1)
        pointsTableViewHeightAnchor?.isActive = true
        pointsTableViewController.didMove(toParent: self)

        installDescriptionText()
    }

    private func installDescriptionText() {
        let descriptionString = viewModel.point.description
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: descriptionString,
                                                                                              attributes: [NSAttributedString.Key.font : GeneralFonts.text,
                                                                                                           NSAttributedString.Key.foregroundColor: GeneralColors.text]))
        let compatibleSourceString = NSString(string: descriptionString) // NSAttributedString requires NSRange which only comes from NSString

        viewModel.point.hyperlinks.forEach { (pointHyperlink) in
            let substring = pointHyperlink.substring
            // Only will apply the hyperlink to the first instance of the substring
            let range = compatibleSourceString.range(of: substring, options: .caseInsensitive)
            if range.location != NSNotFound {
                attributedString.addAttribute(.link, value: pointHyperlink.url, range: range)
            }
        }

        descriptionTextView.attributedText = attributedString
        descriptionTextView.sizeToFit()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pointsTableViewHeightAnchor?.constant = pointsTableViewController.pointsTableViewHeight
    }

    // MARK: View binding

    private func installViewBinds() {
        descriptionTextView.delegate = self

        viewModel.pointHandlingErrorRelay.subscribe { errorEvent in
            if let generalError = errorEvent.element as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard let moyaError = errorEvent.element as? MoyaError,
                let response = moyaError.response else {
                    ErrorHandler.showBasicErrorBanner()
                    return
            }

            switch response.statusCode {
            case 404:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: GeneralError.report.localizedDescription))
            default:
                ErrorHandler.showBasicErrorBanner()
            }
        }.disposed(by: disposeBag)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
