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

        markAsSeen()

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
    private static let inset: CGFloat = 16.0

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

    private lazy var imagePageViewController: UIPageViewController = {
        let imagePageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        if let firstPointImageViewController = viewModel.getImagePage(at: 0) {
            imagePageViewController.setViewControllers([firstPointImageViewController],
                                                       direction: .forward,
                                                       animated: false,
                                                       completion: nil)
        }
        return imagePageViewController
    }()

    private lazy var imagePageControl: UIPageControl = {
        let imagePageControl = UIPageControl(frame: .zero)
        imagePageControl.numberOfPages = viewModel.pointImagesCount
        imagePageControl.pageIndicatorTintColor = .customLightGray1
        imagePageControl.currentPageIndicatorTintColor = .customDarkGreen1
        imagePageControl.currentPage = 0
        return imagePageControl
    }()

    private lazy var pointsTableViewController = PointsTableViewController(viewModel: PointsTableViewModel(debate: viewModel.debate,
                                                                                                           viewState: .embeddedRebuttals,
                                                                                                           rebuttals: viewModel.point.rebuttals))
}

// MARK: - View constraints & binding
extension PointViewController: UITextViewDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    // MARK: View constraints

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background

        view.addSubview(descriptionTextView)
        addChild(imagePageViewController)
        view.addSubview(imagePageViewController.view)
        addChild(pointsTableViewController)
        view.addSubview(pointsTableViewController.view)

        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        imagePageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pointsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false

        descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PointViewController.inset).isActive = true
        descriptionTextView.topAnchor.constraint(equalTo: topLayoutAnchor, constant: PointViewController.inset).isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PointViewController.inset).isActive = true

        imagePageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PointViewController.inset).isActive = true
        imagePageViewController.view.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: PointViewController.inset).isActive = true
        imagePageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PointViewController.inset).isActive = true
        imagePageViewController.view.bottomAnchor.constraint(equalTo: pointsTableViewController.view.topAnchor,
                                                             constant: -PointViewController.inset).injectPriority(.required - 1).isActive = true
        imagePageViewController.didMove(toParent: self)

        pointsTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pointsTableViewController.view.topAnchor.constraint(greaterThanOrEqualTo: descriptionTextView.bottomAnchor).isActive = true
        pointsTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pointsTableViewController.view.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        pointsTableViewHeightAnchor = pointsTableViewController.view.heightAnchor.constraint(equalToConstant: 0.0).injectPriority(.required - 1)
        pointsTableViewHeightAnchor?.isActive = true
        pointsTableViewController.didMove(toParent: self)

        if viewModel.pointImagesCount > 1 {
            view.addSubview(imagePageControl)
            imagePageControl.translatesAutoresizingMaskIntoConstraints = false
            imagePageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            imagePageControl.topAnchor.constraint(equalTo: imagePageViewController.view.bottomAnchor, constant: PointViewController.inset).isActive = true
            imagePageControl.bottomAnchor.constraint(equalTo: pointsTableViewController.view.topAnchor, constant: -PointViewController.inset).isActive = true
        }

        installDescriptionText()
    }

    private func installDescriptionText() {
        guard let attributedString = MarkDownFormatter.formatBold(in: viewModel.point.description, regularAttributes: [.font : GeneralFonts.text,
                                                                                                                       .foregroundColor: GeneralColors.text]) else {
                return
        }

        let compatibleSourceString = NSString(string: attributedString.string) // NSAttributedString requires NSRange which only comes from NSString

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
        imagePageViewController.dataSource = self
        imagePageViewController.delegate = self
    }

    private func markAsSeen() {
        viewModel.markAsSeen()?.subscribe(onError: { (error) in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard let moyaError = error as? MoyaError,
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
        }).disposed(by: disposeBag)
    }

    // MARK: UITextViewDelegate

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }

    // MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewModel.getIndexOf(viewController) else {
            return nil
        }

        return viewModel.getImagePage(at: index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewModel.getIndexOf(viewController) else {
            return nil
        }

        return viewModel.getImagePage(at: index + 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let pageContentViewController = pageViewController.viewControllers?.first,
            let newIndex = viewModel.getIndexOf(pageContentViewController) else {
            return
        }

        UIView.animate(withDuration: Constants.standardAnimationDuration) { [weak self] in
            self?.imagePageControl.currentPage = newIndex
        }
    }
}
