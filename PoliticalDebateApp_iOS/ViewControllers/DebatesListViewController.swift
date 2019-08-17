//
//  DebatesListViewController.swift
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
class DebatesListViewController: UIViewController {

    required init(viewModel: DebateListViewModel) {
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

    // MARK: - Dependencies

    private let sessionManager = SessionManager.shared

    // MARK: - Observers & Observables

    private let viewModel: DebateListViewModel
    private let disposeBag = DisposeBag()

    private let searchTriggeredRelay = BehaviorRelay<String>(value: DebatesListViewController.defaultSearchString)
    private let sortSelectionRelay = BehaviorRelay<SortByOption>(value: SortByOption.defaultValue)
    private let userActionRelay = BehaviorRelay<Void>(value: ())

    // MARK: - Synchronizing animations

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

    private let sortByButton = BasicUIElementFactory.generateButton(title: DebatesListViewController.sortByDefaultlabel, titleColor: GeneralColors.softButton)

    private let sortByPickerView: UIPickerView = {
        let sortByPickerView = UIPickerView()
        sortByPickerView.backgroundColor = GeneralColors.background
        return sortByPickerView
    }()

    private let searchTextField: UITextField = BasicUIElementFactory.generateTextField(placeholder: "Search...")

    private let searchButtonBar: UIToolbar = {
        let searchButtonBar = UIToolbar()
        let searchButton = UIBarButtonItem(title: "Search",
                                           style: .plain,
                                           target: self,
                                           action: #selector(activateSearch))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                            target: self,
                                            action: nil)

        searchButton.tintColor = GeneralColors.hardButton
        searchButton.setTitleTextAttributes([.font : GeneralFonts.button as Any], for: .normal)
        searchButtonBar.items = [flexibleSpace, searchButton]
        searchButtonBar.sizeToFit()
        searchButtonBar.barTintColor = GeneralColors.navBarTint
        return searchButtonBar
    }()

    private let collectionViewContainer = UIView(frame: .zero) // so we can use gradient fade on container not the collectionView's scrollView

    private let debatesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        // Not using flow layout delegate
        layout.minimumLineSpacing = DebatesListViewController.cellSpacing
        layout.minimumInteritemSpacing = DebatesListViewController.cellSpacing
        let screenWidth = UIScreen.main.bounds.width
        let cellWidthAndHeight = (screenWidth - (3 * DebatesListViewController.cellSpacing))/2
        layout.itemSize = CGSize(width: cellWidthAndHeight, height: cellWidthAndHeight)

        let debatesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        debatesCollectionView.backgroundColor = .clear
        debatesCollectionView.contentInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
        debatesCollectionView.alwaysBounceVertical = true
        return debatesCollectionView
    }()

    private let debatesRefreshControl = UIRefreshControl()

    private let emptyStateLabel: UILabel = {
        let emptyStateLabel = UILabel(frame: .zero)
        emptyStateLabel.text = "No debates to show."
        emptyStateLabel.textColor = UIColor.customDarkGray1
        emptyStateLabel.font = UIFont.primaryRegular(24.0)
        emptyStateLabel.textAlignment = NSTextAlignment.center
        emptyStateLabel.alpha = 0.0
        return emptyStateLabel
    }()

}

extension DebatesListViewController: UITextFieldDelegate {

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
extension DebatesListViewController: UICollectionViewDelegate, UIScrollViewDelegate {

    // MARK: View constraints
    // swiftlint:disable:next function_body_length
    private func installViewConstraints() {
        view.backgroundColor = DebatesListViewController.backgroundColor
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]
        navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint

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

        headerElementsContainer.backgroundColor = DebatesListViewController.backgroundColor
        headerElementsContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        headerElementsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: DebatesListViewController.headerElementsXDistance).isActive = true
        headerElementsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -DebatesListViewController.headerElementsXDistance).isActive = true

        searchTextField.topAnchor.constraint(equalTo: headerElementsContainer.topAnchor,
                                             constant: DebatesListViewController.headerElementsYDistance).isActive = true
        searchTextFieldTrailingAnchor = searchTextField.trailingAnchor.constraint(equalTo: sortByButton.leadingAnchor, constant: -8)
        searchTextFieldTrailingAnchor?.isActive = false
        searchTextField.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true
        searchTextField.leadingAnchor.constraint(equalTo: headerElementsContainer.leadingAnchor).isActive = true

        sortByButton.topAnchor.constraint(equalTo: searchTextField.topAnchor, constant: -2).isActive = true
        sortByButton.bottomAnchor.constraint(equalTo: headerElementsContainer.bottomAnchor).isActive = true
        sortByButton.trailingAnchor.constraint(equalTo: headerElementsContainer.trailingAnchor).isActive = true
        sortByButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        sortByButton.setContentHuggingPriority(.required, for: .horizontal)

        sortByPickerViewTopAnchor = sortByPickerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: -8)
        sortByPickerViewTopAnchor?.isActive = false
        sortByPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -DebatesListViewController.headerElementsXDistance).isActive = true
        sortByPickerViewBottomAnchor = sortByPickerView.bottomAnchor.constraint(equalTo: view.topAnchor)
        sortByPickerViewBottomAnchor?.isActive = true
        sortByPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: DebatesListViewController.headerElementsXDistance).isActive = true

        collectionViewContainer.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 2).isActive = true
        collectionViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -DebatesListViewController.cellSpacing).isActive = true
        collectionViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        collectionViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: DebatesListViewController.cellSpacing).isActive = true

        debatesCollectionView.topAnchor.constraint(equalTo: collectionViewContainer.topAnchor).isActive = true
        debatesCollectionView.trailingAnchor.constraint(equalTo: collectionViewContainer.trailingAnchor).isActive = true
        debatesCollectionView.bottomAnchor.constraint(equalTo: collectionViewContainer.bottomAnchor).isActive = true
        debatesCollectionView.leadingAnchor.constraint(equalTo: collectionViewContainer.leadingAnchor).isActive = true

        emptyStateLabel.centerXAnchor.constraint(equalTo: collectionViewContainer.centerXAnchor).isActive = true
        emptyStateLabel.centerYAnchor.constraint(equalTo: collectionViewContainer.centerYAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionViewContainer.fadeView(style: .vertical, percentage: 0.04)
        sortByPickerView.fadeView(style: .bottom, percentage: 0.1)
    }

    // MARK: View binding

    private func installViewBinds() {
        searchTextField.delegate = self
        searchTextField.inputAccessoryView = searchButtonBar

        sessionManager.isActiveRelay.subscribe { [weak self] isActive in
            guard let isActive = isActive.element else { return }
            if isActive {
                self?.navigationItem.rightBarButtonItem = self?.accountButton.barButton
            } else {
                self?.navigationItem.rightBarButtonItem = self?.loginButton.barButton
            }
        }.disposed(by: disposeBag)

        loginButton.button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        accountButton.button.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
        sortByButton.addTarget(self, action: #selector(togglePickerViewOnScreen), for: .touchUpInside)

        // Set up picker options
        Observable.just(SortByOption.allCases.map { $0.stringValue })
            .bind(to: sortByPickerView.rx.itemTitles) { _, optionLabel in
                optionLabel
            }.disposed(by: disposeBag)

        sortByPickerView.rx.itemSelected.subscribe({ [weak self] itemEvent in
            guard let item = itemEvent.element else { return }

            self?.hideActiveUIElements()
            self?.updateSortBySelection(with: item.row)
            self?.sortSelectionRelay.accept(SortByOption(rawValue: item.row) ?? SortByOption.defaultValue)
        }).disposed(by: disposeBag)

        viewModel.subscribeToManualDebateUpdates(searchTriggeredRelay.asDriver(),
                                                 sortSelectionRelay.asDriver(),
                                                 userActionRelay.asDriver())

        animationBlocksRelay.subscribe { animationEvent in
            guard let animationBlock = animationEvent.element else { return }
            animationBlock()
        }.disposed(by: disposeBag)

        debatesRefreshControl.addTarget(self, action: #selector(userPulledToRefresh), for: .valueChanged)
        debatesCollectionView.refreshControl = debatesRefreshControl

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
        userActionRelay.accept(())
        hideActiveUIElements()
    }

    @objc private func activateSearch() {
        searchTriggeredRelay.accept(searchTextField.text ?? DebatesListViewController.defaultSearchString)
        hideActiveUIElements()
    }

    private func installCollectionViewDataSource() {
        debatesCollectionView.register(DebateCell.self, forCellWithReuseIdentifier: DebateCell.reuseIdentifier)
        viewModel.debatesViewModelRelay
            .skip(1) // empty array emission initialized w/ relay
            .do(onNext: { [weak self] debateViewModels in
                self?.debatesRefreshControl.endRefreshing()
                UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
                    self?.emptyStateLabel.alpha = debateViewModels.isEmpty ? 1.0 : 0.0
                })
            })
            .bind(to: debatesCollectionView.rx.items(cellIdentifier: DebateCell.reuseIdentifier, cellType: DebateCell.self)) { _, viewModel, cell in
            cell.viewModel = viewModel
        }.disposed(by: disposeBag)

        viewModel.debatesRetrievalErrorRelay.subscribe { errorEvent in
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

    // MARK: - UI Animation handling

    @objc private func hideActiveUIElements() {
        hidePickerView() // If user taps away to dismiss picker, they have not changed selection
        resignSearchTextField()
    }

    private func resignSearchTextField() {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
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
    }

    private func updateSortBySelection(with pickerChoice: Int) {
        animationBlocksRelay.accept { [weak self] in
            guard let sortByButton = self?.sortByButton else { return }
            UIView.transition(with: sortByButton, duration: Constants.standardAnimationDuration, options: .transitionCrossDissolve, animations: {
                let optionSelected = SortByOption(rawValue: pickerChoice)
                self?.sortByButton.setTitle(optionSelected?.stringValue ?? DebatesListViewController.sortByDefaultlabel,
                                            for: .normal)
                self?.sortByButton.setTitleColor(optionSelected?.selectionColor, for: .normal)
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
