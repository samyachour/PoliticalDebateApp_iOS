//
//  DebatesCollectionViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

// Acts as our home view as well
class DebatesCollectionViewController: UIViewController {

    required init(viewModel: DebatesCollectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil) // we don't use nibs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        UserDataManager.shared.loadUserData { [weak self] in
            self?.installViewConstraints()
            self?.installViewBinds()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.refreshDebatesWithLocalData()
    }

    // MARK: - Dependencies

    private let sessionManager = SessionManager.shared

    // MARK: - Observers & Observables

    private let viewModel: DebatesCollectionViewModel
    private let disposeBag = DisposeBag()

    private let searchTriggeredRelay = BehaviorRelay<String>(value: DebatesCollectionViewController.defaultSearchString)
    private let sortSelectionRelay = BehaviorRelay<SortByOption>(value: SortByOption.defaultValue)
    private let manualRefreshRelay = BehaviorRelay<Void>(value: ())

    // On this screen we are constantly running multiple animations at once
    // There is a problem when animation blocks are not called serially
    // They start to overlap and the parameters (duration, options, etc.) bleed into each other
    // To prevent this we enforce synchronization with a relay
    private var animationBlocksRelay = PublishRelay<() -> Void>()

    // MARK: - UI Properties

    private static let headerElementsYDistance: CGFloat = 12.0
    private static let headerElementsXDistance: CGFloat = 16.0
    private static let sortByDefaultlabel = SortByOption.defaultValue.stringValue
    private static let defaultSearchString = ""
    private static let cellSpacing: CGFloat = 24.0
    private var pickerIsOnScreen: Bool {
        return sortByPickerViewTopAnchor?.isActive ?? false &&
            !(sortByPickerViewBottomAnchor?.isActive ?? false)
    }
    private var searchTextFieldTrailingAnchor: NSLayoutConstraint?
    private var sortByPickerViewTopAnchor: NSLayoutConstraint?
    private var sortByPickerViewBottomAnchor: NSLayoutConstraint?
    private static let backgroundColor = GeneralColors.background

    // MARK: - UI Elements

    private let loginButton = BasicUIElementFactory.generateBarButton(title: "Log in")

    private let accountButton = BasicUIElementFactory.generateBarButton(title: "Account")

    private let headerElementsContainer = UIView(frame: .zero)

    private let sortByButton = BasicUIElementFactory.generateButton(title: DebatesCollectionViewController.sortByDefaultlabel, titleColor: GeneralColors.softButton)

    private let sortByPickerView: UIPickerView = {
        let sortByPickerView = UIPickerView()
        sortByPickerView.backgroundColor = GeneralColors.background
        return sortByPickerView
    }()

    private let searchTextField: UITextField = BasicUIElementFactory.generateTextField(placeholder: "Search...", returnKeyType: .search)

    private let collectionViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private var orientedCollectionViewItemSize: CGSize {
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        let widthDividend: CGFloat = isPortrait ? 2 : 3
        let spaces: CGFloat = isPortrait ? 3 : 4
        let cellWidthAndHeight = (UIScreen.main.bounds.width - (spaces * DebatesCollectionViewController.cellSpacing))/widthDividend
        return CGSize(width: cellWidthAndHeight, height: cellWidthAndHeight)
    }
    private lazy var currentItemSize = orientedCollectionViewItemSize

    private lazy var debatesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        // Not using flow layout delegate
        layout.minimumLineSpacing = DebatesCollectionViewController.cellSpacing
        layout.minimumInteritemSpacing = DebatesCollectionViewController.cellSpacing
        layout.itemSize = currentItemSize

        let debatesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        debatesCollectionView.backgroundColor = .clear
        debatesCollectionView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
        debatesCollectionView.alwaysBounceVertical = true
        return debatesCollectionView
    }()

    private let debatesRefreshControl = UIRefreshControl()

    private let emptyStateLabel = BasicUIElementFactory.generateEmptyStateLabel(text: "No debates to show.")

}

extension DebatesCollectionViewController: UITextFieldDelegate {

    // Expand the text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animationBlocksRelay.accept { [weak self] in
            UIView.animate(withDuration: Constants.standardAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                self?.searchTextFieldTrailingAnchor?.isActive = true
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" { // If user clicks enter perform search
            activateSearch()
            return false
        }
        return true
    }

}

// MARK: - View constraints & binding
extension DebatesCollectionViewController: UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: View constraints
    // swiftlint:disable:next function_body_length
    private func installViewConstraints() {
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle]
        navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint
        view.backgroundColor = DebatesCollectionViewController.backgroundColor

        headerElementsContainer.addSubview(searchTextField)
        headerElementsContainer.addSubview(sortByButton)
        view.addSubview(collectionViewContainer)
        view.addSubview(sortByPickerView)
        collectionViewContainer.addSubview(emptyStateLabel)
        collectionViewContainer.addSubview(debatesCollectionView)
        view.addSubview(headerElementsContainer)

        headerElementsContainer.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        sortByButton.translatesAutoresizingMaskIntoConstraints = false
        sortByPickerView.translatesAutoresizingMaskIntoConstraints = false
        collectionViewContainer.translatesAutoresizingMaskIntoConstraints = false
        debatesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        headerElementsContainer.backgroundColor = DebatesCollectionViewController.backgroundColor
        headerElementsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: DebatesCollectionViewController.headerElementsXDistance).isActive = true
        headerElementsContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        headerElementsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -DebatesCollectionViewController.headerElementsXDistance).isActive = true

        searchTextField.leadingAnchor.constraint(equalTo: headerElementsContainer.leadingAnchor).isActive = true
        searchTextField.topAnchor.constraint(equalTo: headerElementsContainer.topAnchor,
                                             constant: DebatesCollectionViewController.headerElementsYDistance).isActive = true
        searchTextFieldTrailingAnchor = searchTextField.trailingAnchor.constraint(equalTo: sortByButton.leadingAnchor, constant: -8)
        searchTextFieldTrailingAnchor?.isActive = false
        searchTextField.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true

        sortByButton.topAnchor.constraint(equalTo: searchTextField.topAnchor, constant: -2).isActive = true
        sortByButton.trailingAnchor.constraint(equalTo: headerElementsContainer.trailingAnchor).isActive = true
        sortByButton.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true
        sortByButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        sortByButton.setContentHuggingPriority(.required, for: .horizontal)

        sortByPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: DebatesCollectionViewController.headerElementsXDistance).isActive = true
        sortByPickerViewTopAnchor = sortByPickerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: -8)
        sortByPickerViewTopAnchor?.isActive = false
        sortByPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -DebatesCollectionViewController.headerElementsXDistance).isActive = true
        sortByPickerViewBottomAnchor = sortByPickerView.bottomAnchor.constraint(equalTo: view.topAnchor)
        sortByPickerViewBottomAnchor?.isActive = true

        collectionViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: DebatesCollectionViewController.cellSpacing).isActive = true
        collectionViewContainer.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 2).isActive = true
        collectionViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -DebatesCollectionViewController.cellSpacing).isActive = true
        collectionViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        debatesCollectionView.leadingAnchor.constraint(equalTo: collectionViewContainer.leadingAnchor).isActive = true
        debatesCollectionView.topAnchor.constraint(equalTo: collectionViewContainer.topAnchor).isActive = true
        debatesCollectionView.trailingAnchor.constraint(equalTo: collectionViewContainer.trailingAnchor).isActive = true
        debatesCollectionView.bottomAnchor.constraint(equalTo: collectionViewContainer.bottomAnchor).isActive = true
        debatesCollectionView.alpha = 0.0

        emptyStateLabel.centerXAnchor.constraint(equalTo: collectionViewContainer.centerXAnchor).isActive = true
        emptyStateLabel.centerYAnchor.constraint(equalTo: collectionViewContainer.centerYAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionViewContainer.fadeView(style: .vertical, percentage: 0.04)
        sortByPickerView.fadeView(style: .bottom, percentage: 0.1)
    }

    // MARK: Collection view flow layout delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return orientedCollectionViewItemSize
    }

    // MARK: View binding
    // swiftlint:disable:next function_body_length
    private func installViewBinds() {
        searchTextField.delegate = self

        sessionManager.isActiveRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isActive in
                if isActive {
                    self?.navigationItem.rightBarButtonItem = self?.accountButton.barButton
                } else {
                    self?.navigationItem.rightBarButtonItem = self?.loginButton.barButton
                }
            }).disposed(by: disposeBag)

        loginButton.button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        accountButton.button.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
        sortByButton.addTarget(self, action: #selector(togglePickerViewOnScreen), for: .touchUpInside)

        // Set up picker options
        Observable.just(SortByOption.allCases.map { $0.stringValue })
            .bind(to: sortByPickerView.rx.itemTitles) { _, optionLabel in
                optionLabel
            }.disposed(by: disposeBag)

        sortByPickerView.rx.itemSelected.subscribe(onNext: { [weak self] item in
            self?.activateSearch() // make sure we search w/ the latest value
            self?.sortSelectionRelay.accept(SortByOption(rawValue: item.row) ?? SortByOption.defaultValue)
        }).disposed(by: disposeBag)

        let sharedSortSelectionRelay = sortSelectionRelay.asDriver().asSharedSequence()

        sharedSortSelectionRelay.drive(onNext: { [weak self] pickerChoice in
            self?.updateSortBySelection(pickerChoice)
        }).disposed(by: disposeBag)

        viewModel.subscribeToManualDebateUpdates(searchTriggeredRelay.asDriver(),
                                                 sharedSortSelectionRelay,
                                                 manualRefreshRelay.asDriver())

        animationBlocksRelay.subscribe(onNext: { animationBlock in
            animationBlock()
        }).disposed(by: disposeBag)

        debatesRefreshControl.addTarget(self, action: #selector(userPulledToRefresh), for: .valueChanged)
        debatesCollectionView.refreshControl = debatesRefreshControl

        debatesCollectionView.delegate = self

        debatesCollectionView.rx
            .modelSelected(DebateCollectionViewCellViewModel.self)
            .subscribe(onNext: { [weak self] (debateCollectionViewCellViewModel) in
                self?.navigationController?
                    .pushViewController(PointsTableViewController(viewModel: PointsTableViewModel(debate: debateCollectionViewCellViewModel.debate,
                                                                                                  isStarred: debateCollectionViewCellViewModel.isStarred,
                                                                                                  viewState: .standalone)),
                                        animated: true)
        }).disposed(by: disposeBag)

        installCollectionViewDataSource()
    }

    @objc private func loginTapped() {
        navigationController?.pushViewController(LoginOrRegisterViewController(viewModel: LoginOrRegisterViewModel()),
                                                 animated: true)
    }

    @objc private func accountTapped() {
        navigationController?.pushViewController(AccountViewController(viewModel: AccountViewModel()),
                                                 animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { hideActiveUIElements() }

    @objc private func userPulledToRefresh() {
        manualRefreshRelay.accept(())
        hideActiveUIElements()
    }

    @objc private func activateSearch() {
        searchTriggeredRelay.accept(searchTextField.text ?? DebatesCollectionViewController.defaultSearchString)
        hideActiveUIElements()
    }

    private func installCollectionViewDataSource() {
        debatesCollectionView.register(DebateCollectionViewCell.self, forCellWithReuseIdentifier: DebateCollectionViewCell.reuseIdentifier)
        viewModel.sharedDebatesDataSourceRelay
            .subscribe(onNext: { [weak self] (debateCollectionViewCellViewModels) in
                self?.debatesRefreshControl.endRefreshing()
                UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
                    self?.emptyStateLabel.alpha = debateCollectionViewCellViewModels.isEmpty ? 1.0 : 0.0
                    self?.debatesCollectionView.alpha = debateCollectionViewCellViewModels.isEmpty ? 0.0 : 1.0
                })
            }).disposed(by: disposeBag)

        viewModel.sharedDebatesDataSourceRelay
            .bind(to: debatesCollectionView.rx.items(cellIdentifier: DebateCollectionViewCell.reuseIdentifier,
                                                     cellType: DebateCollectionViewCell.self)) { _, viewModel, cell in
            cell.viewModel = viewModel
        }.disposed(by: disposeBag)

        viewModel.debatesRetrievalErrorRelay.subscribe(onNext: { [weak self] error in
            self?.debatesRefreshControl.endRefreshing()

            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard let moyaError = error as? MoyaError,
                let response = moyaError.response else {
                    ErrorHandler.showBasicRetryErrorBanner()
                    return
            }

            switch response.statusCode {
            case 400:
                ErrorHandler.showBasicReportErrorBanner()
            default:
                ErrorHandler.showBasicRetryErrorBanner()
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - UI Animation handling

    @objc private func hideActiveUIElements() {
        hidePickerView()
        resignSearchTextField()
    }

    private func resignSearchTextField() {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
        }
        if searchTextField.text?.isEmpty ?? true { // Shrink the text field if it's empty
            animationBlocksRelay.accept { [weak self] in
                UIView.animate(withDuration: Constants.standardAnimationDuration,
                               delay: 0.0,
                               options: .curveEaseInOut,
                               animations: {
                                self?.searchTextFieldTrailingAnchor?.isActive = false
                                self?.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }

    private func updateSortBySelection(_ pickerChoice: SortByOption) {
        animationBlocksRelay.accept { [weak self] in
            guard let sortByButton = self?.sortByButton else { return }
            UIView.transition(with: sortByButton, duration: Constants.standardAnimationDuration, options: .transitionCrossDissolve, animations: {
                self?.sortByButton.setTitle(pickerChoice.stringValue,
                                            for: .normal)
                self?.sortByButton.setTitleColor(pickerChoice.selectionColor, for: .normal)
            }, completion: nil)
        }
    }

    private func hidePickerView() {
        if pickerIsOnScreen { togglePickerViewOnScreen() }
    }

    @objc private func togglePickerViewOnScreen() {
        let toggle = !pickerIsOnScreen

        animationBlocksRelay.accept { [weak self] in
            UIView.animate(withDuration: 0.7, delay: 0.0, options: .curveEaseInOut, animations: {
                // Need to disable and enable constraints in the correct order to prevent errors
                if self?.sortByPickerViewTopAnchor?.isActive ?? false {
                    self?.sortByPickerViewTopAnchor?.isActive = toggle
                    self?.sortByPickerViewBottomAnchor?.isActive = !toggle
                } else if self?.sortByPickerViewBottomAnchor?.isActive ?? false {
                    self?.sortByPickerViewBottomAnchor?.isActive = !toggle
                    self?.sortByPickerViewTopAnchor?.isActive = toggle
                }
                self?.view.layoutIfNeeded()
            })
        }
    }
}

// MARK: - Device rotation
extension DebatesCollectionViewController {
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.debatesCollectionView.collectionViewLayout.invalidateLayout()
            if let orientedCollectionViewItemSize = self?.orientedCollectionViewItemSize {
                self?.currentItemSize = orientedCollectionViewItemSize
            }
        })
    }
}
