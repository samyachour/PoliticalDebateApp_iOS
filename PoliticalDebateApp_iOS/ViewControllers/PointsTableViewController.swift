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
        super.init(nibName: nil, bundle: nil)
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

    // MARK: - Observers & Observables

    private let viewModel: PointsTableViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    var hasLaidOutSubviews = false

    static let elementSpacing: CGFloat = 16.0

    private var tableViewContainerHeightAnchor: NSLayoutConstraint?
    private var pointsTableViewBottomAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var tableViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private lazy var pointsTableView: UITableView = {
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

    private lazy var undoButton: UIButton = {
        let undoButton = UIButton(frame: .zero)
        undoButton.setImage(UIImage.undoArrow, for: .normal)
        let inset: CGFloat = 8.0
        undoButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: 0)
        return undoButton
    }()

}

extension PointsTableViewController {

    // MARK: - View constraints

    private func installViewConstraints() {
        switch viewModel.viewState {
        case .standaloneRootPoints:
            navigationItem.title = viewModel.debate.shortTitle
            navigationController?.navigationBar.tintColor = GeneralColors.navBarButton
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                       .font: GeneralFonts.navBarTitle]
            starredButton.tintColor = viewModel.starTintColor
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: starredButton)
            view.backgroundColor = GeneralColors.background
        case .embeddedPointHistory:
            parent?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: undoButton)
            fallthrough
        case .embeddedRebuttals:
            view.backgroundColor = .clear
        }

        view.addSubview(tableViewContainer)
        tableViewContainer.addSubview(pointsTableView)

        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        pointsTableView.translatesAutoresizingMaskIntoConstraints = false

        tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        pointsTableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor).isActive = true
        pointsTableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor).isActive = true
        pointsTableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor).isActive = true
        pointsTableViewBottomAnchor = pointsTableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor)
        pointsTableViewBottomAnchor?.isActive = true

        switch viewModel.viewState {
        case .embeddedRebuttals:
            // Set the height to the entire screen at a lower priority so when we disable the bottom anchor it will expand to that size
            // and we can recompute based on visible cell height
            pointsTableView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).injectPriority(.required - 2).isActive = true
            recomputeTableViewHeight(animated: false)
        case .embeddedPointHistory:
            updateTableViewContainerHeight(justLastCell: true)
        case .standaloneRootPoints:
            break
        }
    }

    private func recomputeTableViewHeight(animated: Bool = true) {
        self.pointsTableViewBottomAnchor?.isActive = false
        self.view.layoutIfNeeded()

        UIView.animate(withDuration: animated ? GeneralConstants.standardAnimationDuration : 0,
                       animations: {
                        self.updateTableViewContainerHeight()
                        self.pointsTableViewBottomAnchor?.isActive = true
                        self.view.layoutIfNeeded()
                        self.view.superview?.layoutIfNeeded()
                },
                       completion: { _ in
                        self.viewModel.completedRecomputingTableViewHeightRelay.accept(())
                })
    }

    private func updateTableViewContainerHeight(justLastCell: Bool = false) {
        let pointsTableViewContentHeight = justLastCell ? pointsTableView.dynamicLastCellContentHeight : pointsTableView.dynamicContentHeight
        if tableViewContainerHeightAnchor == nil {
            tableViewContainerHeightAnchor = justLastCell ?
                tableViewContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: pointsTableViewContentHeight) :
                tableViewContainer.heightAnchor.constraint(equalToConstant: pointsTableViewContentHeight).injectPriority(.required - 1)
            tableViewContainerHeightAnchor?.isActive = true
        } else {
            tableViewContainerHeightAnchor?.constant = pointsTableViewContentHeight
        }
    }

    private func scrollToLastCell() {
        let lastIndexPath = IndexPath(row: viewModel.pointsCount - 1, section: 0)
        pointsTableView.scrollToRow(at: lastIndexPath,
                                    at: .bottom,
                                    animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hasLaidOutSubviews = true

        tableViewContainer.fadeView(style: .vertical, percentage: 0.03)
    }

    // MARK: View binding

    private func installViewBinds() {
        pointsTableView.register(PointTableViewCell.self, forCellReuseIdentifier: PointTableViewCell.reuseIdentifier)

        let dataSource =
            RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>(configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: PointTableViewCell.reuseIdentifier, for: indexPath)
                if let pointTableViewCell = cell as? PointTableViewCell { pointTableViewCell.viewModel = viewModel }
                return cell
            })

        viewModel.pointsDataSourceDriver
            .drive(pointsTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        switch viewModel.viewState {
        case .standaloneRootPoints:
            installRootPointsTableViewBinds()
        case .embeddedPointHistory:
            installEmbeddedPointHistoryTableViewBinds(dataSource: dataSource)
        case .embeddedRebuttals:
            installEmbeddedRebuttalsTableViewBinds(dataSource: dataSource)
        }

        viewModel.observe(indexPathSelected: pointsTableView.rx.itemSelected,
                          modelSelected: pointsTableView.rx.modelSelected(PointTableViewCellViewModel.self),
                          undoSelected: undoButton.rx.tap)
    }

    // MARK: - View binds

    // MARK: Embedded rebuttals binds

    private func installEmbeddedRebuttalsTableViewBinds(dataSource: RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>) {
        viewModel.pointsDataSourceDriver.drive(onNext: { [weak self] _ in
            self?.recomputeTableViewHeight()
        }).disposed(by: disposeBag)
    }

    // MARK: Embedded point history binds

    private func installEmbeddedPointHistoryTableViewBinds(dataSource: RxTableViewSectionedAnimatedDataSourceWithReloadSignal<PointsTableViewSection>) {
        viewModel.popSelfViewControllerSignal.emit(onNext: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)

        Signal.merge(dataSource.dataReloadedSignal, viewModel.completedRecomputingTableViewHeightSignal)
            .emit(onNext: { [weak self] _ in
                guard self?.hasLaidOutSubviews == true else { return }

                self?.scrollToLastCell()
                self?.updateTableViewContainerHeight(justLastCell: true)
        }).disposed(by: disposeBag)
    }

    // MARK: Standalone root points binds

    private func installRootPointsTableViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)

        viewModel.viewControllerToPushSignal.emit(onNext: { [weak self] viewController in
            self?.navigationController?.pushViewController(viewController, animated: true)
        }).disposed(by: disposeBag)
    }

    @objc private func starredButtonTapped() {
        viewModel.starOrUnstarDebate().subscribe(onSuccess: { [weak self] _ in
            UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, animations: {
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
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        navigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}

// MARK: UITableView dynamicContentHeight

private extension UITableView {
    var dynamicContentHeight: CGFloat {
        guard !visibleCells.isEmpty else { return 0.0 }

        let verticalInsets = contentInset.top + contentInset.bottom
        return verticalInsets + visibleCells.reduce(0.0, { (result, cell) -> CGFloat in
            return result + cell.frame.height
        })
    }

    var dynamicLastCellContentHeight: CGFloat {
        guard !visibleCells.isEmpty else { return 0.0 }

        let verticalInsets = contentInset.top + contentInset.bottom
        return verticalInsets + (visibleCells.last?.frame.height ?? 0)
    }
}
