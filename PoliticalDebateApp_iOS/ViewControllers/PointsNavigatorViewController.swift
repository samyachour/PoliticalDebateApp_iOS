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

    private let viewModel: PointsNavigatorViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Properties

    private static let inset: CGFloat = 16.0

    // MARK: - UI Elements

    private lazy var pointHistoryTableViewModel = PointsTableViewModel(debate: viewModel.debate,
                                                                       viewState: .embeddedPointHistory(embeddedSidedPoints: [viewModel.rootPoint]))
    private lazy var pointHistoryTableViewController = PointsTableViewController(viewModel: pointHistoryTableViewModel)

    private lazy var rebuttalsLabel = BasicUIElementFactory.generateHeadingLabel(text: "Rebuttals")

    private lazy var pointRebuttalsTableViewModel = PointsTableViewModel(debate: viewModel.debate,
                                                                         viewState: .embeddedRebuttals(embeddedSidedPoints: viewModel.rootPoint.rebuttals ?? []))
    private lazy var pointRebuttalsTableViewController = PointsTableViewController(viewModel: pointRebuttalsTableViewModel)
}

// MARK: - View constraints & binding
extension PointsNavigatorViewController {

    // MARK: View constraints

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.navBarButton
        view.backgroundColor = GeneralColors.background

        addChild(pointHistoryTableViewController)
        view.addSubview(pointHistoryTableViewController.view)
        view.addSubview(rebuttalsLabel)
        addChild(pointRebuttalsTableViewController)
        view.addSubview(pointRebuttalsTableViewController.view)

        pointHistoryTableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        rebuttalsLabel.translatesAutoresizingMaskIntoConstraints = false
        pointRebuttalsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false

        pointHistoryTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pointHistoryTableViewController.view.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        pointHistoryTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pointHistoryTableViewController.didMove(toParent: self)

        rebuttalsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rebuttalsLabel.topAnchor.constraint(equalTo: pointHistoryTableViewController.view.bottomAnchor).isActive = true
        rebuttalsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rebuttalsLabel.alpha = 0
        toggleRebuttalsLabel(viewModel.rootPoint.rebuttals?.isEmpty == false)

        pointRebuttalsTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pointRebuttalsTableViewController.view.topAnchor.constraint(equalTo: rebuttalsLabel.bottomAnchor).isActive = true
        pointRebuttalsTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pointRebuttalsTableViewController.view.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        pointRebuttalsTableViewController.didMove(toParent: self)

    }

    private func toggleRebuttalsLabel(_ on: Bool) {
        // Fading in the label must be delayed
        // so it doesn't appear at the bottom of the screen
        let delay = rebuttalsLabel.alpha == 0 ? 0.5 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.animate(withDuration: GeneralConstants.standardAnimationDuration) {
                self.rebuttalsLabel.alpha = on ? 1 : 0
            }
        }
    }

    // MARK: View binding

    private func installViewBinds() {
        pointHistoryTableViewModel.observe(newPointSignal: pointRebuttalsTableViewModel.newPointSignal)
        pointHistoryTableViewModel.observe(completedShowingTableViewSignal: pointRebuttalsTableViewModel.completedShowingTableViewSignal)
        pointRebuttalsTableViewModel.observe(newRebuttalsSignal: pointHistoryTableViewModel.newRebuttalsSignal)

        pointHistoryTableViewModel.newRebuttalsSignal
            .emit(onNext: { [weak self] newRebuttals in
                self?.toggleRebuttalsLabel(!newRebuttals.isEmpty)
        }).disposed(by: disposeBag)
    }
}
