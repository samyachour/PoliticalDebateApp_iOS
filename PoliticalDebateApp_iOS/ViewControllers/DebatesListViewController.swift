//
//  DebatesListViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

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

        installViewConstraints()
        installViewBinds()
    }

    // MARK: - Dependencies
    private let sessionManager = SessionManager.shared

    // MARK: - Observers & Observables

    private let viewModel: DebateListViewModel
    private let disposeBag = DisposeBag()

    private let searchTriggeredSubject = PublishSubject<String>()

    @objc private func didCompleteSearchInputOrPickerSelection() {
        if searchTextField.isFirstResponder {
            // No matter the sender that dismisses the keyboard, run a search query w/ the given text
            searchTriggeredSubject.onNext(searchTextField.text ?? "")
            searchTextField.resignFirstResponder()
        }
        if pickerIsOnScreen { // If user taps away to dismiss picker, they have not changed selection
            removePickerView()
        }
    }

    // MARK: - UI Properties

    private static let cornerButtonYDistance: CGFloat = 12.0
    private static let cornerButtonXDistance: CGFloat = 16.0
    private static let sortByDefaultlabel = SortByOption.sortBy.stringValue
    private static let cellSpacing: CGFloat = 24.0
    private var pickerIsOnScreen: Bool {
        return sortByPickerView.superview == self.view
    }
    private var searchTextFieldTrailing: NSLayoutConstraint?

    // MARK: - UI Elements

    // Need to be able to add target to UIButton but use UIBarButtonItem in nav bar
    private let loginButton = BasicUIElementFactory.generateBarButton(title: "Log in")

    private let accountButton = BasicUIElementFactory.generateBarButton(title: "Account")

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
                                           action: #selector(didCompleteSearchInputOrPickerSelection))
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
        return debatesCollectionView
    }()

}

extension DebatesListViewController: UITextFieldDelegate {

    // Expand the text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: Constants.standardAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.searchTextFieldTrailing?.isActive = true
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

    // Shrink the text field if it's empty
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            UIView.animate(withDuration: Constants.standardAnimationDuration,
                           delay: 0.0,
                           options: .curveEaseInOut,
                           animations: { [weak self] in
                            self?.searchTextFieldTrailing?.isActive = false
                            self?.view.layoutIfNeeded()
                }, completion: nil)
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" { // If user clicks enter perform search
            didCompleteSearchInputOrPickerSelection()
            return false
        }
        return true
    }

}

// MARK: - View constraints & binding
extension DebatesListViewController: UICollectionViewDelegate, UIScrollViewDelegate {

    private func installViewConstraints() {

        view.backgroundColor = GeneralColors.background
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]
        navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint

        view.addSubview(searchTextField)
        view.addSubview(sortByButton)
        view.addSubview(collectionViewContainer)
        collectionViewContainer.addSubview(debatesCollectionView)

        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        sortByButton.translatesAutoresizingMaskIntoConstraints = false
        collectionViewContainer.translatesAutoresizingMaskIntoConstraints = false
        debatesCollectionView.translatesAutoresizingMaskIntoConstraints = false

        searchTextField.topAnchor.constraint(equalTo: topLayoutAnchor,
                                             constant: DebatesListViewController.cornerButtonYDistance).isActive = true
        searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: DebatesListViewController.cornerButtonXDistance).isActive = true
        searchTextFieldTrailing = searchTextField.trailingAnchor.constraint(equalTo: sortByButton.leadingAnchor, constant: -8)
        searchTextFieldTrailing?.isActive = false

        sortByButton.topAnchor.constraint(equalTo: searchTextField.topAnchor, constant: -2).isActive = true
        sortByButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                               constant: -DebatesListViewController.cornerButtonXDistance).isActive = true

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionViewContainer.fadeView(style: .vertical, percentage: 0.04)
        sortByPickerView.fadeView(style: .bottom, percentage: 0.1)
    }

    private func installViewBinds() {
        searchTextField.delegate = self
        searchTextField.inputAccessoryView = searchButtonBar

        SessionManager.shared.isActiveRelay.subscribe { [weak self] isActive in
            guard let isActive = isActive.element else { return }
            if isActive {
                self?.navigationItem.rightBarButtonItem = self?.accountButton.barButton
            } else {
                self?.navigationItem.rightBarButtonItem = self?.loginButton.barButton
            }
        }.disposed(by: disposeBag)

        loginButton.button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        accountButton.button.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
        sortByButton.addTarget(self, action: #selector(installPickerView), for: .touchUpInside)

        // Set up picker options
        Observable.just(SortByOption.allCases.map { $0.stringValue })
            .bind(to: sortByPickerView.rx.itemTitles) { _, optionLabel in
                optionLabel
            }.disposed(by: disposeBag)

        let sortSelectionObservable = sortByPickerView.rx.itemSelected.asDriver().do(onNext: { [weak self] item in
            self?.updateSortBySelection(with: item.row)
            self?.didCompleteSearchInputOrPickerSelection()
        }).map { item -> SortByOption in
            SortByOption(rawValue: item.row) ?? .sortBy
        }

        viewModel.subscribeToSearchAndSortQueries(searchInput: searchTriggeredSubject, sortSelection: sortSelectionObservable)

        let navBarTitleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(navBarTitleTapped))
        navBarTitleTapGestureRecognizer.cancelsTouchesInView = false
        navigationController?.navigationBar.addGestureRecognizer(navBarTitleTapGestureRecognizer)

        installCollectionViewDelegate()
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

    private func installCollectionViewDelegate() {
        debatesCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        debatesCollectionView.rx.itemSelected.subscribe { [weak self] (_) in
            self?.didCompleteSearchInputOrPickerSelection()
        }.disposed(by: disposeBag)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        didCompleteSearchInputOrPickerSelection()
    }

    @objc private func navBarTitleTapped() {
        debatesCollectionView.setContentOffset(.zero, animated: true)
    }

    private func installCollectionViewDataSource() {
        debatesCollectionView.register(DebateCell.self, forCellWithReuseIdentifier: DebateCell.reuseIdentifier)
        viewModel.debatesRelay.bind(to: debatesCollectionView.rx.items(cellIdentifier: DebateCell.reuseIdentifier, cellType: DebateCell.self)) { _, viewModel, cell in
            cell.viewModel = viewModel
        }.disposed(by: disposeBag)
    }

    // MARK: - sortByPickerView UI handling

    private func updateSortBySelection(with pickerChoice: Int) {
        UIView.transition(with: sortByButton, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            let optionSelected = SortByOption(rawValue: pickerChoice)
            self?.sortByButton.setTitle(optionSelected?.stringValue ?? DebatesListViewController.sortByDefaultlabel,
                                        for: .normal)
            self?.sortByButton.setTitleColor(optionSelected?.selectionColor, for: .normal)
        })
    }

    @objc private func installPickerView() {
        guard !pickerIsOnScreen else {
            didCompleteSearchInputOrPickerSelection()
            return
        }

        sortByPickerView.alpha = 0.0
        view.addSubview(sortByPickerView)

        sortByPickerView.translatesAutoresizingMaskIntoConstraints = false
        sortByPickerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor).isActive = true
        sortByPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -DebatesListViewController.cornerButtonXDistance).isActive = true
        sortByPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: DebatesListViewController.cornerButtonXDistance).isActive = true

        UIView.animate(withDuration: Constants.standardAnimationDuration) { [weak self] in
            self?.sortByPickerView.alpha = 1.0
        }
    }

    private func removePickerView() {
        UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
            self?.sortByPickerView.alpha = 0.0
            }, completion: { [weak self] _ in // flag not reliable
                self?.sortByPickerView.removeFromSuperview()
        })

    }
}
