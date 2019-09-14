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

        viewModel.retrieveAllDebatePoints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshSeenPoints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.viewState == .standalone {
            UIView.animate(withDuration: Constants.standardAnimationDuration) { [weak self] in
                self?.navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint
                self?.navigationController?.navigationBar.layoutIfNeeded()
            }
        }
    }

    // MARK: - Observers & Observables

    private let viewModel: PointsTableViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    var pointsTableViewHeight: CGFloat { return pointsTableView.dynamicContentHeight }

    // MARK: - UI Elements

    private let tableViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private let pointsTableView: UITableView = {
        let pointsTableView = UITableView(frame: .zero)
        pointsTableView.separatorStyle = .none
        pointsTableView.backgroundColor = .clear
        pointsTableView.rowHeight = UITableView.automaticDimension
        pointsTableView.estimatedRowHeight = 50
        pointsTableView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
        return pointsTableView
    }()

    private lazy var starredButton: UIButton = {
        let starredButton = UIButton(frame: .zero)
        starredButton.setImage(UIImage.star, for: .normal)
        return starredButton
    }()

    private lazy var emptyStateLabel = BasicUIElementFactory.generateEmptyStateLabel(text: "No points to show.")
}

// MARK: - View constraints & binding
extension PointsTableViewController {

    // MARK: View constraints

    private func installViewConstraints() {
        if viewModel.viewState == .standalone {
            navigationItem.title = viewModel.debate.shortTitle
            navigationController?.navigationBar.tintColor = GeneralColors.softButton
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                       .font: GeneralFonts.navBarTitle]
            starredButton.tintColor = viewModel.starTintColor
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: starredButton)
            view.backgroundColor = GeneralColors.background
        } else {
            pointsTableView.alwaysBounceVertical = false
            view.backgroundColor = .clear
        }

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

        tableViewContainer.fadeView(style: .vertical, percentage: 0.03)
    }

    // MARK: View binding

    private func installViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)

        pointsTableView.rx
            .modelSelected(PointTableViewCellViewModel.self)
            .subscribe { [weak self] pointTableViewCellViewModelEvent in
                guard let pointTableViewCellViewModel = pointTableViewCellViewModelEvent.element,
                let debate = self?.viewModel.debate else {
                    return
                }

                self?.navigationController?.pushViewController(PointViewController(viewModel: PointViewModel(point: pointTableViewCellViewModel.point,
                                                                                                             debate: debate)),
                                                               animated: true)
        }.disposed(by: disposeBag)

        installTableViewDataSource()
    }

    private func installTableViewDataSource() {
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
                    ErrorHandler.showBasicErrorBanner()
                    return
                }

                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't save starred debate to server."))
        }).disposed(by: disposeBag)
    }
}

private extension UITableView {
    var dynamicContentHeight: CGFloat {
        layoutIfNeeded()
        let verticalInsets = contentInset.top + contentInset.bottom
        return verticalInsets + visibleCells.reduce(0.0, { (result, cell) -> CGFloat in
            return result + cell.frame.height
        })
    }
}
