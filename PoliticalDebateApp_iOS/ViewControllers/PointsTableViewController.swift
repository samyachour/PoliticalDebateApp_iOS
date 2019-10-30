//
//  PointsTableViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class PointsTableViewController: UIViewController {

    required init(viewModel: PointsTableViewModel) {
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

        viewModel.retrieveAllDebatePoints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.tableViewReloadRelay.accept(())
    }

    // MARK: - Observers & Observables

    private let viewModel: PointsTableViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    var pointsTableViewHeight: CGFloat { return pointsTableView.dynamicContentHeight }
    static let elementSpacing: CGFloat = 16.0
    private var pointsTableViewHeightAnchor: NSLayoutConstraint?
    private var tableViewContainerTopAnchor: NSLayoutConstraint? {
        didSet {
            if let oldValue = oldValue {
                oldValue.isActive = false
                tableViewContainer.removeConstraint(oldValue)
            }
            tableViewContainerTopAnchor?.isActive = true
        }
    }

    // MARK: - UI Elements

    private let loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        loadingIndicator.color = .customDarkGray2
        loadingIndicator.hidesWhenStopped = true
        return loadingIndicator
    }()

    private let contextTextViewsStackView: UIStackView = {
        let contextTextViewsStackView = UIStackView(frame: .zero)
        contextTextViewsStackView.alignment = .leading
        contextTextViewsStackView.axis = .vertical
        contextTextViewsStackView.spacing = PointsTableViewController.elementSpacing
        return contextTextViewsStackView
    }()

    private let tableViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private let pointsTableView: UITableView = {
        let pointsTableView = UITableView(frame: .zero)
        pointsTableView.separatorStyle = .none
        pointsTableView.backgroundColor = .clear
        pointsTableView.rowHeight = UITableView.automaticDimension
        pointsTableView.estimatedRowHeight = 50
        pointsTableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
        pointsTableView.delaysContentTouches = false
        return pointsTableView
    }()

    private lazy var starredButton: UIButton = {
        let starredButton = UIButton(frame: .zero)
        starredButton.setImage(UIImage.star, for: .normal)
        return starredButton
    }()

    private lazy var undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: nil)

}

extension PointsTableViewController {

    // MARK: - View constraints

    // swiftlint:disable:next function_body_length
    private func installViewConstraints() {
        switch viewModel.viewState {
        case .standaloneRootPoints:
            navigationItem.title = viewModel.debate.shortTitle
            navigationController?.navigationBar.tintColor = GeneralColors.softButton
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                       .font: GeneralFonts.navBarTitle]
            starredButton.tintColor = viewModel.starTintColor
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: starredButton)
            view.backgroundColor = GeneralColors.background
            installLoadingIndicator()
        case .embeddedPointHistory:
            parent?.navigationItem.rightBarButtonItem = undoButton
            fallthrough
        case .embeddedRebuttals:
            view.backgroundColor = .clear
        }

        view.addSubview(tableViewContainer)
        tableViewContainer.addSubview(pointsTableView)

        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        pointsTableView.translatesAutoresizingMaskIntoConstraints = false

        tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        pointsTableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor).isActive = true
        pointsTableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor).isActive = true
        pointsTableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor).isActive = true
        pointsTableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor).isActive = true

        switch viewModel.viewState {
        case .standaloneRootPoints:
            view.addSubview(contextTextViewsStackView)
            contextTextViewsStackView.translatesAutoresizingMaskIntoConstraints = false
            contextTextViewsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PointsTableViewController.elementSpacing).isActive = true
            contextTextViewsStackView.topAnchor.constraint(equalTo: topLayoutAnchor, constant: PointsTableViewController.elementSpacing).isActive = true
            contextTextViewsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PointsTableViewController.elementSpacing).isActive = true
            contextTextViewsStackView.alpha = 0.0

            tableViewContainerTopAnchor = tableViewContainer.topAnchor.constraint(equalTo: contextTextViewsStackView.bottomAnchor, constant: 4)
        case .embeddedRebuttals:
            pointsTableViewHeightAnchor = pointsTableView.heightAnchor.constraint(equalToConstant: pointsTableView.dynamicContentHeight)
            pointsTableViewHeightAnchor?.isActive = true
            fallthrough
        case .embeddedPointHistory:
            tableViewContainerTopAnchor = tableViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor)
        }
    }

    private func installLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.startAnimating()
    }

    private func updateContentTextViewsStackView(shouldShow: Bool) {
        switch viewModel.viewState {
        case .standaloneRootPoints where !shouldShow,
            .embeddedPointHistory,
            .embeddedRebuttals:
            tableViewContainerTopAnchor = tableViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor)
            contextTextViewsStackView.removeFromSuperview()
        case .standaloneRootPoints:
            break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableViewContainer.fadeView(style: .vertical, percentage: 0.03)
    }

    // MARK: View binding

    private func installViewBinds() {
        pointsTableView.register(SidedPointTableViewCell.self, forCellReuseIdentifier: SidedPointTableViewCell.reuseIdentifier)

        let dataSource =
            RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>(configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: SidedPointTableViewCell.reuseIdentifier, for: indexPath)
                if let sidedPointTableViewCell = cell as? SidedPointTableViewCell { sidedPointTableViewCell.viewModel = viewModel }
                return cell
            })

        viewModel.sharedSidedPointsDataSourceRelay
            .bind(to: pointsTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        switch viewModel.viewState {
        case .standaloneRootPoints:
            installRootPointsTableViewBinds()
            installContextTextViewsDataSource()
        case .embeddedPointHistory:
            installEmbeddedPointHistoryTableViewBinds(dataSource: dataSource)
        case .embeddedRebuttals:
            installEmbeddedRebuttalsTableViewBinds(dataSource: dataSource)
        }

        viewModel.observe(indexPathSelected: pointsTableView.rx.itemSelected,
                          modelSelected: pointsTableView.rx.modelSelected(SidedPointTableViewCellViewModel.self),
                          undoSelected: undoButton.rx.tap)
    }

    // MARK: - View binds

    // MARK: Embedded rebuttals binds

    private func installEmbeddedRebuttalsTableViewBinds(dataSource: RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>) {
        dataSource.dataReloaded.emit(onNext: { [weak self] _ in
            guard let pointsTableViewHeight = self?.pointsTableView.dynamicContentHeight else { return }

            UIView.animate(withDuration: Constants.standardAnimationDuration * 0.8) {
                self?.pointsTableViewHeightAnchor?.constant = pointsTableViewHeight
                self?.pointsTableView.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
    }

    // MARK: Embedded point history binds

    private func installEmbeddedPointHistoryTableViewBinds(dataSource: RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>) {
        viewModel.popSelfViewControllerRelay.subscribe { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)

        dataSource.dataReloaded.emit(onNext: { [weak self] _ in
            guard let viewModel = self?.viewModel else { return }

            let lastIndexPath = IndexPath(row: viewModel.sidedPointsCount - 1, section: 0)
            self?.pointsTableView.scrollToRow(at: lastIndexPath,
                                              at: .bottom,
                                              animated: true)
        }).disposed(by: disposeBag)
    }

    // MARK: Standalone root points binds

    private func installRootPointsTableViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)

        viewModel.viewControllerToPushRelay.subscribe(onNext: { [weak self] viewController in
            self?.navigationController?.pushViewController(viewController, animated: true)
        }).disposed(by: disposeBag)

        viewModel.sharedSidedPointsDataSourceRelay
            .subscribe(onNext: { [weak self] pointsTableViewCellViewModels in
                UIView.animate(withDuration: Constants.standardAnimationDuration, animations: {
                    self?.contextTextViewsStackView.alpha = pointsTableViewCellViewModels.isEmpty ? 0.0 : 1.0
                    self?.loadingIndicator.stopAnimating()
                })
            }).disposed(by: disposeBag)

        viewModel.pointsRetrievalErrorRelay.subscribe(onNext: { error in
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
            case 400:
                ErrorHandlerService.showBasicReportErrorBanner()
            case _ where Constants.retryErrorCodes.contains(response.statusCode):
                ErrorHandlerService.showBasicRetryErrorBanner { [weak self] in
                    self?.viewModel.retrieveAllDebatePoints()
                }
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }).disposed(by: disposeBag)
    }

    private func installContextTextViewsDataSource() {
        viewModel.sharedContextPointsDataSourceRelay.subscribe(onNext: { [weak self] contextPoints in
            self?.updateContentTextViewsStackView(shouldShow: !contextPoints.isEmpty)
            guard !contextPoints.isEmpty else { return }

            let contextTextViews: [UITextView] = contextPoints.map { [weak self] contextPoint in
                let contextTextView = BasicUIElementFactory.generateDescriptionTextView(MarkDownFormatter.format(contextPoint.description,
                                                                                                                 with: [.font: GeneralFonts.text,
                                                                                                                        .foregroundColor: GeneralColors.text],
                                                                                                                 hyperlinks: contextPoint.hyperlinks))
                guard let self = self else { return contextTextView }

                contextTextView.delegate = self
                return contextTextView
            }
            contextTextViews.forEach { self?.contextTextViewsStackView.addArrangedSubview($0) }
        }).disposed(by: disposeBag)
    }

    @objc private func starredButtonTapped() {
        viewModel.starOrUnstarDebate().subscribe(onSuccess: { [weak self] _ in
            UIView.animate(withDuration: Constants.standardAnimationDuration, animations: {
                self?.starredButton.tintColor = self?.viewModel.starTintColor
            })
            }, onError: { error in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }
                guard error as? MoyaError != nil else {
                    ErrorHandlerService.showBasicRetryErrorBanner()
                    return
                }

                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't save starred debate to server."))
        }).disposed(by: disposeBag)
    }
}

// MARK: UITextViewDelegate

extension PointsTableViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}

// MARK: UITableView dynamicContentHeight

private extension UITableView {
    var dynamicContentHeight: CGFloat {
        layoutIfNeeded()
        guard !visibleCells.isEmpty else { return 0.0 }

        let verticalInsets = contentInset.top + contentInset.bottom
        return verticalInsets + visibleCells.reduce(0.0, { (result, cell) -> CGFloat in
            return result + cell.frame.height
        })
    }
}
