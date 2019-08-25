//
//  PointsTableViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
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

        viewModel.retrieveFullDebate()
        viewModel.retrieveSeenPoints()
    }

    var isFirstViewWillAppear = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // No need to refresh on the first call to viewWillAppear
        if isFirstViewWillAppear {
            isFirstViewWillAppear = false
        } else {
            viewModel.refreshSeenPoints()
        }
    }

    // MARK: - Observers & Observables

    private let viewModel: PointsTableViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    private let tableViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private let pointsTableView: UITableView = {
        let pointsTableView = UITableView(frame: .zero)
        pointsTableView.separatorStyle = .none
        pointsTableView.backgroundColor = .clear
        pointsTableView.rowHeight = UITableView.automaticDimension
        pointsTableView.estimatedRowHeight = 50
        return pointsTableView
    }()

    private let emptyStateLabel = BasicUIElementFactory.generateEmptyStateLabel(text: "No points to show.")
}

// MARK: - View constraints & binding
extension PointsTableViewController: UICollectionViewDelegate, UIScrollViewDelegate {

    // MARK: View constraints

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]

        view.addSubview(tableViewContainer)
        tableViewContainer.addSubview(pointsTableView)
        tableViewContainer.addSubview(emptyStateLabel)

        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        pointsTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        pointsTableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor).isActive = true
        pointsTableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor).isActive = true
        pointsTableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor).isActive = true
        pointsTableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor).isActive = true

        emptyStateLabel.centerXAnchor.constraint(equalTo: tableViewContainer.centerXAnchor).isActive = true
        emptyStateLabel.centerYAnchor.constraint(equalTo: tableViewContainer.centerYAnchor).isActive = true

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableViewContainer.fadeView(style: .vertical, percentage: 0.04)
    }

    // MARK: View binding

    private func installViewBinds() {
        viewModel.debateTitleRelay.subscribe { [weak self] shortTitleEvent in
            guard let shortTitle = shortTitleEvent.element else { return }

            self?.navigationItem.title = shortTitle
        }.disposed(by: disposeBag)

        installCollectionViewDataSource()
    }

    private func installCollectionViewDataSource() {
        pointsTableView.register(PointTableViewCell.self, forCellReuseIdentifier: PointTableViewCell.reuseIdentifier)
        viewModel.sharedPointsDataSourceRelay
            .subscribe({ [weak self] (pointsDataSourceEvent) in
                guard let pointsCollectionViewCellViewModels = pointsDataSourceEvent.element else {
                    return
                }

                UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
                    self?.emptyStateLabel.alpha = pointsCollectionViewCellViewModels.isEmpty ? 1.0 : 0.0
                })
            }).disposed(by: disposeBag)

        viewModel.sharedPointsDataSourceRelay
            .bind(to: pointsTableView.rx.items(cellIdentifier: PointTableViewCell.reuseIdentifier,
                                               cellType: PointTableViewCell.self)) { _, viewModel, cell in
                                                cell.viewModel = viewModel
            }.disposed(by: disposeBag)

        viewModel.pointsRetrievalErrorRelay.subscribe { errorEvent in
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
            case 400:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: GeneralError.report.localizedDescription))
            default:
                ErrorHandler.showBasicErrorBanner()
            }
            }.disposed(by: disposeBag)
    }
}
