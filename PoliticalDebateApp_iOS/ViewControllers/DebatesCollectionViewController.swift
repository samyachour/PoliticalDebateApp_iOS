//
//  DebatesCollectionViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

// swiftlint:disable file_length

/// Root home view listing all debates
class DebatesCollectionViewController: UIViewController, SynchronizableAnimation {

    required init(viewModel: DebatesCollectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        installViewConstraints()
        installViewBinds()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.triggerRefreshDebatesWithLocalData()
    }

    // MARK: - Observers & Observables

    private let viewModel: DebatesCollectionViewModel
    let disposeBag = DisposeBag()

    // User can dismiss the keyboard without manually triggering a new serach
    // but on the next query we need to use that latest search string
    typealias UpdatedSearch = (searchString: String?, manual: Bool)
    private let searchUpdatedRelay = PublishRelay<UpdatedSearch>()
    private let sortSelectionRelay = PublishRelay<SortByOption>()
    private let manualRefreshRelay = PublishRelay<Void>()

    // SynchronizableAnimation
    let isExecutingAnimation = BehaviorRelay<Bool>(value: false)

    private lazy var showLoadingIndicatorRelay = BehaviorRelay<Bool>(value: true)
    private lazy var showRetryButtonRelay = BehaviorRelay<Bool>(value: false)

    // MARK: - UI Properties

    private static let headerElementsYDistance: CGFloat = 12.0
    private static let headerElementsXDistance: CGFloat = 16.0
    private static let sortByDefaultlabel = SortByOption.defaultValue.stringValue
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

    private lazy var loginButton = BasicUIElementFactory.generateBarButton(title: "Log in")

    private lazy var accountButton = BasicUIElementFactory.generateBarButton(title: "Account")

    private lazy var headerElementsContainer = UIView(frame: .zero)

    private lazy var sortByButton = BasicUIElementFactory.generateButton(title: DebatesCollectionViewController.sortByDefaultlabel,
                                                                         titleColor: GeneralColors.softButton)

    private lazy var sortByPickerView: UIPickerView = {
        let sortByPickerView = UIPickerView()
        sortByPickerView.backgroundColor = GeneralColors.background
        return sortByPickerView
    }()

    private lazy var searchTextField: UITextField = BasicUIElementFactory.generateTextField(placeholder: "Search...",
                                                                                            returnKeyType: .search)

    private lazy var collectionViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private var orientedCollectionViewItemSize: CGSize {
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        let widthDividend: CGFloat = isPortrait ? 2 : 3
        let spaces: CGFloat = isPortrait ? 3 : 4
        let cellWidthAndHeight = (UIScreen.main.bounds.width - (spaces * Self.cellSpacing))/widthDividend
        return CGSize(width: cellWidthAndHeight, height: cellWidthAndHeight)
    }
    private lazy var currentItemSize = orientedCollectionViewItemSize

    private lazy var debatesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        // Not using flow layout delegate
        layout.minimumLineSpacing = Self.cellSpacing
        layout.minimumInteritemSpacing = Self.cellSpacing
        layout.itemSize = currentItemSize

        let debatesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        debatesCollectionView.backgroundColor = .clear
        debatesCollectionView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
        debatesCollectionView.alwaysBounceVertical = true
        debatesCollectionView.delaysContentTouches = false
        return debatesCollectionView
    }()

    private lazy var debatesRefreshControl = UIRefreshControl()

    private lazy var loadingIndicator = BasicUIElementFactory.generateLoadingIndicator()

    private lazy var emptyStateLabel = BasicUIElementFactory.generateEmptyStateLabel(text: "No debates to show.")

    private lazy var retryButton = BasicUIElementFactory.generateButton(title: GeneralCopies.retryTitle, font: UIFont.primaryRegular(24))

}

extension DebatesCollectionViewController: UITextFieldDelegate {

    // Expand the text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        executeSynchronousAnimation { [weak self] completion in
            UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                self?.searchTextFieldTrailingAnchor?.isActive = true
                self?.view.layoutIfNeeded()
            }, completion: completion)
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

    // MARK: - View constraints
    // swiftlint:disable:next function_body_length
    private func installViewConstraints() {
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle]
        navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint
        view.backgroundColor = Self.backgroundColor

        headerElementsContainer.addSubview(searchTextField)
        headerElementsContainer.addSubview(sortByButton)
        view.addSubview(collectionViewContainer)
        view.addSubview(sortByPickerView)
        collectionViewContainer.addSubview(emptyStateLabel)
        collectionViewContainer.addSubview(debatesCollectionView)
        view.addSubview(headerElementsContainer)
        view.addSubview(loadingIndicator)
        view.addSubview(retryButton)

        headerElementsContainer.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        sortByButton.translatesAutoresizingMaskIntoConstraints = false
        sortByPickerView.translatesAutoresizingMaskIntoConstraints = false
        collectionViewContainer.translatesAutoresizingMaskIntoConstraints = false
        debatesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        headerElementsContainer.backgroundColor = Self.backgroundColor
        headerElementsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: Self.headerElementsXDistance).isActive = true
        headerElementsContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        headerElementsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -Self.headerElementsXDistance).isActive = true

        searchTextField.leadingAnchor.constraint(equalTo: headerElementsContainer.leadingAnchor).isActive = true
        searchTextField.topAnchor.constraint(equalTo: headerElementsContainer.topAnchor,
                                             constant: Self.headerElementsYDistance).isActive = true
        searchTextFieldTrailingAnchor = searchTextField.trailingAnchor.constraint(equalTo: sortByButton.leadingAnchor, constant: -8)
        searchTextFieldTrailingAnchor?.isActive = false
        searchTextField.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true

        sortByButton.topAnchor.constraint(equalTo: searchTextField.topAnchor, constant: -2).isActive = true
        sortByButton.trailingAnchor.constraint(equalTo: headerElementsContainer.trailingAnchor).isActive = true
        sortByButton.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true
        sortByButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        sortByButton.setContentHuggingPriority(.required, for: .horizontal)

        sortByPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: Self.headerElementsXDistance).isActive = true
        sortByPickerViewTopAnchor = sortByPickerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: -8)
        sortByPickerViewTopAnchor?.isActive = false
        sortByPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -Self.headerElementsXDistance).isActive = true
        sortByPickerViewBottomAnchor = sortByPickerView.bottomAnchor.constraint(equalTo: view.topAnchor)
        sortByPickerViewBottomAnchor?.isActive = true

        collectionViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: Self.cellSpacing).isActive = true
        collectionViewContainer.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 2).isActive = true
        collectionViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -Self.cellSpacing).isActive = true
        collectionViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        debatesCollectionView.leadingAnchor.constraint(equalTo: collectionViewContainer.leadingAnchor).isActive = true
        debatesCollectionView.topAnchor.constraint(equalTo: collectionViewContainer.topAnchor).isActive = true
        debatesCollectionView.trailingAnchor.constraint(equalTo: collectionViewContainer.trailingAnchor).isActive = true
        debatesCollectionView.bottomAnchor.constraint(equalTo: collectionViewContainer.bottomAnchor).isActive = true
        debatesCollectionView.alpha = 0.0

        emptyStateLabel.centerXAnchor.constraint(equalTo: collectionViewContainer.centerXAnchor).isActive = true
        emptyStateLabel.centerYAnchor.constraint(equalTo: collectionViewContainer.centerYAnchor).isActive = true

        loadingIndicator.centerXAnchor.constraint(equalTo: collectionViewContainer.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: collectionViewContainer.centerYAnchor).isActive = true

        retryButton.centerXAnchor.constraint(equalTo: collectionViewContainer.centerXAnchor).isActive = true
        retryButton.centerYAnchor.constraint(equalTo: collectionViewContainer.centerYAnchor).isActive = true
        retryButton.alpha = 0
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

    // MARK: - View binding

    private func installViewBinds() {
        installUIBinds()
        installCollectionViewDataSource()
    }

    // MARK: UI Binds

    @objc private func loginTapped() {
        navigationController?.pushViewController(LoginOrRegisterViewController(viewModel: LoginOrRegisterViewModel()),
                                                 animated: true)
    }

    @objc private func accountTapped() {
        navigationController?.pushViewController(AccountViewController(viewModel: AccountViewModel()),
                                                 animated: true)
    }

    @objc private func activateSearch() {
        searchUpdatedRelay.accept((searchTextField.text, true))
    }

    @objc private func userPulledToRefresh() {
        manualRefreshRelay.accept(())
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hideActiveUIElements()
    }

    private func installUIBinds() {
        installUIActions()
        installUIDebateRequestTriggerBinds()
    }

    private func installUIActions() {
        searchTextField.delegate = self

        SessionManager.shared.isActiveDriver
            .drive(onNext: { [weak self] isActive in
                if isActive {
                    self?.navigationItem.rightBarButtonItem = self?.accountButton.barButton
                } else {
                    self?.navigationItem.rightBarButtonItem = self?.loginButton.barButton
                }
            }).disposed(by: disposeBag)

        // Create picker options from SortByOption cases
        Driver.just(SortByOption.allCases.map { $0.stringValue })
            .drive(sortByPickerView.rx.itemTitles) { (_, optionLabel) in
                optionLabel
            }.disposed(by: disposeBag)

        loginButton.button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        accountButton.button.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
        sortByButton.addTarget(self, action: #selector(togglePickerViewOnScreen), for: .touchUpInside)

        sortByPickerView.rx.itemSelected
            .asSignal()
            .map({ item in
                guard let sortSelection = SortByOption(rawValue: item.row) else { fatalError("Sort by option doesn't exist for index \(item.row)") }

                return sortSelection
            })
            .emit(to: sortSelectionRelay)
            .disposed(by: disposeBag)
    }

    // swiftlint:disable:next function_body_length
    private func installUIDebateRequestTriggerBinds() {
        let sortSelectionSignal = sortSelectionRelay.asSignal()
        let searchUpdatedSignal = searchUpdatedRelay.asSignal()
        let manualRefreshSignal = manualRefreshRelay.asSignal()

        viewModel.subscribeToManualDebateUpdates(searchUpdatedSignal,
                                                 sortSelectionSignal,
                                                 manualRefreshSignal)

        let searchTriggeredSignal = searchUpdatedSignal.filter({ $0.manual })
        let searchOrSortSignal = Signal<Void>.merge(sortSelectionSignal.map({ _ in }),
                                                    searchTriggeredSignal.map({ _ in }))
        let allRequestSignal = Signal<Void>.merge(manualRefreshSignal, searchOrSortSignal)

        searchTextField.rx.text
            .asSignal(onErrorJustReturn: nil)
            .withLatestFrom(searchTriggeredSignal.map({ $0.searchString }).startWith(nil)) { ($0, $1) }
            // Make sure these automatic searchString updates aren't the same as the latest manual one
            // to avoid re-entrancy warnings
            .filter({ $0 != $1 })
            .map({ ($0.0, false) })
            .emit(to: searchUpdatedRelay)
            .disposed(by: disposeBag)

        sortSelectionSignal.emit(onNext: { [weak self] pickerChoice in
            self?.updateSortBySelection(pickerChoice)
        }).disposed(by: disposeBag)

        searchOrSortSignal.map({ return true }).emit(to: showLoadingIndicatorRelay).disposed(by: disposeBag)

        searchOrSortSignal
            .emit(onNext: { [weak self] _ in
                guard self?.emptyStateLabel.alpha != 0.0 else { return }

                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration,
                               animations: { self?.emptyStateLabel.alpha = 0.0 })
            })
            .disposed(by: disposeBag)

        // Loading indicator & retry button

        showLoadingIndicatorRelay
            .asDriver()
            .debounce(GeneralConstants.shortDebounceDuration)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] show in
                // Need to start animating before showing, and stop after hiding
                if show { self?.loadingIndicator.startAnimating() }
                UIView.animate(withDuration: GeneralConstants.shortAnimationDuration,
                               animations: { self?.loadingIndicator.alpha = show ? 1 : 0 },
                               completion: { _ in if !show { self?.loadingIndicator.stopAnimating() }})
            }).disposed(by: disposeBag)

        debatesRefreshControl.addTarget(self, action: #selector(userPulledToRefresh), for: .valueChanged)
        debatesCollectionView.refreshControl = debatesRefreshControl

        manualRefreshSignal.map({ return false }).emit(to: showLoadingIndicatorRelay).disposed(by: disposeBag)

        retryButton.rx.tap
            .asSignal()
            .do(afterNext: { [weak self] _ in
                // Typically manual refreshes hide the loading indicator but for this one case we want
                // to show it, so we show it afterNext aka after being hidden (by emitting to manual refresh)
                self?.showLoadingIndicatorRelay.accept(true)
            })
            .emit(to: manualRefreshRelay)
            .disposed(by: disposeBag)

        allRequestSignal
            .map({ return false })
            .emit(to: showRetryButtonRelay)
            .disposed(by: disposeBag)

        allRequestSignal
            .emit(onNext: { [weak self] in
                self?.hideActiveUIElements()
            }).disposed(by: disposeBag)

        Driver.combineLatest(showRetryButtonRelay.asDriver(), viewModel.debatesDataSourceDriver.startWith([]))
            .distinctUntilChanged({ (lhs, rhs) -> Bool in return lhs.0 == rhs.0 }) // only care when the showing retry button value changes
            .drive(onNext: { [weak self] (show, debateCollectionViewSections) in
                // Make sure we don't already have debates on screen before showing
                guard !(show && debateCollectionViewSections.first?.items.isEmpty == false) else { return }

                // Need to unhide before showing and hide after
                if show { self?.retryButton.isHidden = false }
                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration,
                               animations: { self?.retryButton.alpha = show ? 1 : 0 },
                               completion: { _ in if !show { self?.retryButton.isHidden = true }})
            }).disposed(by: disposeBag)
    }

    // MARK: Datasource
    // swiftlint:disable:next function_body_length
    private func installCollectionViewDataSource() {

        // Binds

        debatesCollectionView.rx.setDelegate(self).disposed(by: disposeBag)

        debatesCollectionView.rx
            .modelSelected(DebateCollectionViewCellViewModel.self)
            .subscribe(onNext: { [weak self] debateCollectionViewCellViewModel in
                self?.navigationController?
                    .pushViewController(PointsTableViewController(viewModel: PointsTableViewModel(debate: debateCollectionViewCellViewModel.debate,
                                                                                                  isStarred: debateCollectionViewCellViewModel.isStarred,
                                                                                                  viewState: .standaloneRootPoints)),
                                        animated: true)
        }).disposed(by: disposeBag)

        // Datasource

        debatesCollectionView.register(DebateCollectionViewCell.self, forCellWithReuseIdentifier: DebateCollectionViewCell.reuseIdentifier)
        viewModel.debatesDataSourceDriver
            .drive(onNext: { [weak self] debateCollectionViewSections in
                self?.debatesRefreshControl.endRefreshing()
                self?.showLoadingIndicatorRelay.accept(false)
                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, animations: {
                    self?.emptyStateLabel.alpha = debateCollectionViewSections.first?.items.isEmpty == true ? 1.0 : 0.0
                    self?.debatesCollectionView.alpha = debateCollectionViewSections.first?.items.isEmpty == true ? 0.0 : 1.0
                })
            }).disposed(by: disposeBag)

        let dataSource = RxCollectionViewSectionedAnimatedDataSource<DebatesCollectionViewSection>(
            configureCell: { (_, collectionView, indexPath, viewModel) -> UICollectionViewCell in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DebateCollectionViewCell.reuseIdentifier, for: indexPath)
                if let debateCell = cell as? DebateCollectionViewCell { debateCell.viewModel = viewModel }
                return cell
        })
        viewModel.debatesDataSourceDriver
            .drive(debatesCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        viewModel.debatesRetrievalErrorSignal.emit(onNext: { [weak self] error in
            self?.debatesRefreshControl.endRefreshing()
            self?.showLoadingIndicatorRelay.accept(false)
            self?.showRetryButtonRelay.accept(true)

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
            case _ where GeneralConstants.retryErrorCodes.contains(response.statusCode):
                ErrorHandlerService.showBasicRetryErrorBanner { [weak self] in
                    self?.manualRefreshRelay.accept(())
                }
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - UI Animation handling

    @objc private func hideActiveUIElements() {
        resignSearchTextField()
        hidePickerView()
    }

    private func resignSearchTextField() {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
        }
        // Shrink the text field if it's empty and expanded
        if searchTextField.text?.isEmpty == true &&
            searchTextFieldTrailingAnchor?.isActive == true {
            executeSynchronousAnimation { [weak self] completion in
                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration,
                               delay: 0.0,
                               options: .curveEaseInOut,
                               animations: {
                                self?.searchTextFieldTrailingAnchor?.isActive = false
                                self?.view.layoutIfNeeded()
                }, completion: completion)
            }
        }
    }

    private func updateSortBySelection(_ pickerChoice: SortByOption) {
        executeSynchronousAnimation { [weak self] completion in
            guard let sortByButton = self?.sortByButton else { return }

            UIView.transition(with: sortByButton,
                              duration: GeneralConstants.standardAnimationDuration,
                              options: .transitionCrossDissolve,
                              animations: {
                                self?.sortByButton.setTitle(pickerChoice.stringValue,
                                                            for: .normal)
                                self?.sortByButton.setTitleColor(pickerChoice.selectionColor, for: .normal)
            },
                              completion: completion)
        }
    }

    private func hidePickerView() {
        if pickerIsOnScreen { togglePickerViewOnScreen() }
    }

    @objc private func togglePickerViewOnScreen() {
        let toggle = !pickerIsOnScreen

        executeSynchronousAnimation { [weak self] completion in
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
            }, completion: completion)
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
