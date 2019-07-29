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

    // MARK: - Action handlers

    @objc private func loginTapped() {
        navigationController?.pushViewController(LoginOrRegisterViewController(viewModel: LoginOrRegisterViewModel()),
                                                 animated: true)
    }

    @objc private func accountTapped() {
        navigationController?.pushViewController(AccountViewController(viewModel: AccountViewModel()),
                                                 animated: true)
    }

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
    private static let cornerRadius: CGFloat = 4.0
    private var pickerIsOnScreen: Bool {
        return sortByPickerView.superview == self.view
    }
    private var searchTextFieldWidth: NSLayoutConstraint?
    private var searchTextFieldTrailing: NSLayoutConstraint?

    // MARK: - UI Elements

    // Need to be able to add target to UIButton but use UIBarButtonItem in nav bar
    private let loginButton: (button: UIButton, barButton: UIBarButtonItem) = {
        let loginButton = UIButton(frame: .zero)
        loginButton.setTitle("Log in", for: .normal)
        loginButton.setTitleColor(GeneralColors.softButton, for: .normal)
        loginButton.titleLabel?.font = UIFont.primaryRegular(14.0)
        return (loginButton, UIBarButtonItem(customView: loginButton))
    }()

    private let accountButton: (button: UIButton, barButton: UIBarButtonItem) = {
        let accountButton = UIButton(frame: .zero)
        accountButton.setTitle("Account", for: .normal)
        accountButton.setTitleColor(GeneralColors.softButton, for: .normal)
        accountButton.titleLabel?.font = UIFont.primaryRegular(14.0)
        return (accountButton, UIBarButtonItem(customView: accountButton))
    }()

    private let sortByButton: UIButton = {
        let sortByButton = UIButton(frame: .zero)
        sortByButton.setTitle(DebatesListViewController.sortByDefaultlabel, for: .normal)
        sortByButton.setTitleColor(GeneralColors.softButton, for: .normal)
        sortByButton.titleLabel?.font = GeneralFonts.button
        return sortByButton
    }()

    private let sortByPickerView = UIPickerView()

    private let searchTextField: UITextField = {
        let searchTextField = UITextField(frame: .zero)
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search...",
                                                                   attributes: [
                                                                    .font : GeneralFonts.button as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        searchTextField.font = GeneralFonts.button
        searchTextField.textColor = GeneralColors.hardButton
        searchTextField.borderStyle = .roundedRect
        return searchTextField
    }()

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

}

// Gesture recognizer
extension DebatesListViewController {

    // Can't use TapGesture because I need to trigger the instant the user interacts w/ the screen
    // e.g. beginning of scroll, long press, etc.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // If it was outside our search text field while editing or picker view while open
            let shouldHandleTouch = (!searchTextField.frame.contains(touch.location(in: self.view)) && searchTextField.isFirstResponder) ||
                (!sortByPickerView.frame.contains(touch.location(in: self.view)) && pickerIsOnScreen)
            if shouldHandleTouch { didCompleteSearchInputOrPickerSelection() }
        }
        super.touchesBegan(touches, with: event)
    }
}

extension DebatesListViewController: UITextFieldDelegate {

    // Expand the text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: Constants.standardAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.searchTextFieldWidth?.isActive = false
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
                            self?.searchTextFieldWidth?.isActive = true
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
extension DebatesListViewController {

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
    }

    private func installViewConstraints() {

        view.backgroundColor = GeneralColors.background
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]
        navigationController?.navigationBar.barTintColor = GeneralColors.navBarTint

        view.addSubview(searchTextField)
        view.addSubview(sortByButton)

        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.topAnchor.constraint(equalTo: topLayoutAnchor,
                                             constant: DebatesListViewController.cornerButtonYDistance).isActive = true
        searchTextFieldWidth = searchTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25)
        searchTextFieldWidth?.isActive = true
        searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: DebatesListViewController.cornerButtonXDistance).isActive = true
        searchTextFieldTrailing = searchTextField.trailingAnchor.constraint(equalTo: sortByButton.leadingAnchor, constant: -8)
        searchTextFieldTrailing?.isActive = false

        sortByButton.translatesAutoresizingMaskIntoConstraints = false
        sortByButton.topAnchor.constraint(equalTo: searchTextField.topAnchor, constant: -2).isActive = true
        sortByButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                               constant: -DebatesListViewController.cornerButtonXDistance).isActive = true

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
        sortByPickerView.alpha = 0.0
        view.addSubview(sortByPickerView)

        sortByPickerView.translatesAutoresizingMaskIntoConstraints = false
        sortByPickerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: -8).isActive = true
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
