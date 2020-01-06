//
//  DebatesTableViewController.swift
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

/// Root home view listing all debates
class DebatesTableViewController: UIViewController {

    required init(viewModel: DebatesTableViewModel) {
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

    private let viewModel: DebatesTableViewModel
    let disposeBag = DisposeBag()

    // User can dismiss the keyboard without manually triggering a new serach
    // but on the next query we need to use that latest search string
    typealias UpdatedSearch = (searchString: String?, manual: Bool)
    private let searchUpdatedRelay = PublishRelay<UpdatedSearch>()
    private let sortSelectionRelay = PublishRelay<SortByOption>()
    private let manualRefreshRelay = PublishRelay<Void>()

    private lazy var showLoadingIndicatorRelay = BehaviorRelay<Bool>(value: true)
    private lazy var showRetryButtonRelay = BehaviorRelay<Bool>(value: false)

    // MARK: - UI Properties

    static let verticalInset: CGFloat = 12.0
    static let horizontalInset: CGFloat = 16.0
    private static let backgroundColor = GeneralColors.background

    // MARK: - UI Elements

    private lazy var settingsButton = BasicUIElementFactory.generateBarButton(image: UIImage.gear)

    private lazy var tableViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private lazy var debatesTableView = BasicUIElementFactory.generateTableView()

    private lazy var debatesSearchController: UISearchController = {
        let debatesSearchController = UISearchController(searchResultsController: nil)
        debatesSearchController.obscuresBackgroundDuringPresentation = false
        if UserDefaultsService.hasUsedSearchBar {
            debatesSearchController.searchBar.placeholder = "Search..."
        } else {
            debatesSearchController.searchBar.placeholder = "Try searching \"Immigration\"..."
        }
        debatesSearchController.searchBar.enablesReturnKeyAutomatically = false
        debatesSearchController.searchBar.scopeButtonTitles = SortByOption.allCases.map { $0.stringValue }
        debatesSearchController.searchBar.scopeBar?.apportionsSegmentWidthsByContent = true
        return debatesSearchController
    }()

    private var debatesSearchBar: UISearchBar {
        return debatesSearchController.searchBar
    }

    private lazy var loadingIndicator = BasicUIElementFactory.generateLoadingIndicator()

    private lazy var emptyStateLabel = BasicUIElementFactory.generateEmptyStateLabel(text: "No debates to show.")

    private lazy var retryButton = BasicUIElementFactory.generateButton(title: GeneralCopies.retryTitle, font: UIFont.primaryRegular(24))

}

// MARK: - View constraints & binding
extension DebatesTableViewController {
    // MARK: - View constraints
    private func installViewConstraints() {
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle]
        navigationItem.rightBarButtonItem = settingsButton.barButton
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            navigationItem.searchController = debatesSearchController
        }
        view.backgroundColor = Self.backgroundColor
        definesPresentationContext = true

        view.addSubview(tableViewContainer)
        tableViewContainer.addSubview(debatesTableView)
        tableViewContainer.addSubview(emptyStateLabel)
        tableViewContainer.addSubview(loadingIndicator)
        tableViewContainer.addSubview(retryButton)

        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        debatesTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        tableViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        debatesTableView.leadingAnchor.constraint(equalTo: tableViewContainer.leadingAnchor).isActive = true
        debatesTableView.topAnchor.constraint(equalTo: tableViewContainer.topAnchor).isActive = true
        debatesTableView.trailingAnchor.constraint(equalTo: tableViewContainer.trailingAnchor).isActive = true
        debatesTableView.bottomAnchor.constraint(equalTo: tableViewContainer.bottomAnchor).isActive = true
        debatesTableView.alpha = 0.0

        emptyStateLabel.centerXAnchor.constraint(equalTo: tableViewContainer.centerXAnchor).isActive = true
        emptyStateLabel.centerYAnchor.constraint(equalTo: tableViewContainer.centerYAnchor).isActive = true

        loadingIndicator.centerXAnchor.constraint(equalTo: tableViewContainer.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: tableViewContainer.centerYAnchor).isActive = true

        retryButton.centerXAnchor.constraint(equalTo: tableViewContainer.centerXAnchor).isActive = true
        retryButton.centerYAnchor.constraint(equalTo: tableViewContainer.centerYAnchor).isActive = true
        retryButton.alpha = 0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableViewContainer.fadeView(style: .vertical, percentage: 0.04)
    }

    // MARK: - View binding

    private func installViewBinds() {
        installUIBinds()
        installCollectionViewDataSource()
    }

    // MARK: UI Binds

    @objc private func settingsTapped() {
        if SessionManager.shared.isActive {
            navigationController?.pushViewController(AccountViewController(viewModel: AccountViewModel()),
                                                     animated: true)
        } else {
            navigationController?.pushViewController(LoginOrRegisterViewController(viewModel: LoginOrRegisterViewModel()),
                                                     animated: true)
        }
    }

    // swiftlint:disable:next function_body_length
    private func installUIBinds() {
        settingsButton.button.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)

        debatesSearchBar.scopeBar?.rx.selectedSegmentIndex
            .asSignal(onErrorJustReturn: 0)
            .map({ selectedIndex -> SortByOption in
                guard let sortByOption = SortByOption(rawValue: selectedIndex) else {
                        fatalError("Scope bar title does not match a sort by option")
                }

                return sortByOption
            })
            .emit(to: sortSelectionRelay)
            .disposed(by: disposeBag)

        let sortSelectionSignal = sortSelectionRelay.asSignal()
        let searchUpdatedSignal = searchUpdatedRelay.asSignal()
        let manualRefreshSignal = manualRefreshRelay.asSignal()

        viewModel.subscribeToManualDebateUpdates(searchUpdatedSignal,
                                                 sortSelectionSignal,
                                                 manualRefreshSignal)

        let searchTriggeredSignal = searchUpdatedSignal.filter({ $0.manual }).map({ $0.searchString })
        let searchOrSortSignal = Signal<Void>.merge(sortSelectionSignal.distinctUntilChanged().map({ _ in }),
                                                    searchTriggeredSignal.distinctUntilChanged().map({ _ in }))
        let allRequestSignal = Signal<Void>.merge(manualRefreshSignal, searchOrSortSignal)

        debatesSearchBar.rx.textDidEndEditing
            .asSignal(onErrorJustReturn: ())
            .map({ [weak self] _ -> UpdatedSearch in
                return (self?.debatesSearchBar.text, true)
            })
            .emit(to: searchUpdatedRelay)
            .disposed(by: disposeBag)

        Signal.merge(debatesTableView.rx.willBeginDragging.asSignal(), sortSelectionSignal.map({ _ in }))
            .emit(onNext: { [weak self] _ in
                self?.debatesSearchBar.resignFirstResponder()
            }).disposed(by: disposeBag)

        debatesSearchBar.rx.cancelButtonClicked
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.sortSelectionRelay.accept(SortByOption.defaultValue)
                self?.searchUpdatedRelay.accept((nil, true))
            })
            .disposed(by: disposeBag)

        debatesSearchBar.rx.cancelButtonClicked
            .asDriver()
            .delay(GeneralConstants.shortDelayDuration)
            .drive(onNext: { [weak self] _ in
                self?.debatesSearchBar.scopeBar?.selectedSegmentIndex = SortByOption.defaultValue.rawValue
                self?.debatesSearchBar.text = nil
            })
            .disposed(by: disposeBag)

        debatesSearchBar.rx.text
            .asSignal(onErrorJustReturn: nil)
            .withLatestFrom(searchTriggeredSignal.startWith(nil)) { ($0, $1) }
            // Make sure these automatic searchString updates aren't the same as the latest manual one
            // to avoid re-entrancy warnings
            .filter({ $0 != $1 })
            .map({ ($0.0, false) })
            .emit(to: searchUpdatedRelay)
            .disposed(by: disposeBag)

        searchOrSortSignal.map({ return true }).emit(to: showLoadingIndicatorRelay).disposed(by: disposeBag)

        searchOrSortSignal
            .emit(onNext: { [weak self] _ in
                guard self?.emptyStateLabel.alpha != 0.0 else { return }

                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration,
                               animations: { self?.emptyStateLabel.alpha = 0.0 })
            })
            .disposed(by: disposeBag)

        if !UserDefaultsService.hasUsedSearchBar {
            searchUpdatedSignal.asObservable().take(1)
                .subscribe(onNext: { _ in UserDefaultsService.hasUsedSearchBar = true }).disposed(by: disposeBag)
        }

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

        debatesTableView.rx
            .modelSelected(DebateTableViewCellViewModel.self)
            .subscribe(onNext: { [weak self] debateCollectionViewCellViewModel in
                self?.navigationController?
                    .pushViewController(PointsTableViewController(viewModel: PointsTableViewModel(debate: debateCollectionViewCellViewModel.debate,
                                                                                                  isStarred: debateCollectionViewCellViewModel.isStarred,
                                                                                                  viewState: .standaloneRootPoints)),
                                        animated: true)
        }).disposed(by: disposeBag)

        // Datasource

        debatesTableView.register(DebateTableViewCell.self, forCellReuseIdentifier: DebateTableViewCell.reuseIdentifier)
        viewModel.debatesDataSourceDriver
            .drive(onNext: { [weak self] debateCollectionViewSections in
                self?.showLoadingIndicatorRelay.accept(false)
                UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, animations: {
                    self?.emptyStateLabel.alpha = debateCollectionViewSections.first?.items.isEmpty == true ? 1.0 : 0.0
                    self?.debatesTableView.alpha = debateCollectionViewSections.first?.items.isEmpty == true ? 0.0 : 1.0
                })
            }).disposed(by: disposeBag)

        let dataSource = RxTableViewSectionedAnimatedDataSource<DebatesTableViewSection>(
            configureCell: { (_, tableView, indexPath, viewModel) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: DebateTableViewCell.reuseIdentifier, for: indexPath)
                if let debateTableViewCell = cell as? DebateTableViewCell { debateTableViewCell.viewModel = viewModel }
                return cell
        })

        viewModel.debatesDataSourceDriver
            .drive(debatesTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        viewModel.debatesRetrievalErrorSignal.emit(onNext: { [weak self] error in
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
            case GeneralConstants.customErrorCode:
                ErrorHandlerService.showBasicReportErrorBanner()
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }).disposed(by: disposeBag)
    }
}

// MARK: - UISearchBar extension

private extension UISearchBar {
    var scopeBar: UISegmentedControl? {
        // Only way to access underlying scope bar
        return value(forKey: "_scopeBar") as? UISegmentedControl
    }
}
