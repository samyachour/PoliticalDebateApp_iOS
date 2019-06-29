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
public class DebatesListViewController: UIViewController {

    public required init(viewModel: DebateListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil) // we don't use nibs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: VC Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

        installViewConstraints()
        installViewBinds()
    }

    // MARK: Dependencies
    private let sessionManager = SessionManager.shared

    // MARK: Observers & Observables

    private let viewModel: DebateListViewModel
    private let disposeBag = DisposeBag()

    private func userAuthenticationStateChanged(_ isAuthenticated: Bool) {
        if isAuthenticated {
            navigationItem.rightBarButtonItem = accountButton.barButton
        } else {
            navigationItem.rightBarButtonItem = loginButton.barButton
        }
    }

    private let searchTriggeredSubject = PublishSubject<String>()

    // MARK: Action handlers

    @objc private func loginTapped() {
        navigationController?.pushViewController(LoginViewController(viewModel: LoginViewModel()),
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

    // MARK: UI Properties

    public static let buttonColor = UIColor.customDarkGray1
    public static let selectedColor = UIColor.customDarkGray2
    private static let barTintColor = UIColor.customLightGreen1
    private static let cornerButtonYDistance: CGFloat = 12.0
    private static let cornerButtonXDistance: CGFloat = 16.0
    private static let buttonFont = UIFont.primaryRegular()
    private static let sortByDefaultlabel = SortByOption.sortBy.stringValue
    private static let cornerRadius: CGFloat = 4.0
    private var pickerIsOnScreen: Bool {
        return sortByPickerView.superview == self.view
    }

    // MARK: UI Elements

    // Need to be able to add target to UIButton but use UIBarButtonItem in nav bar
    private let loginButton: (button: UIButton, barButton: UIBarButtonItem) = {
        let loginButton = UIButton(frame: .zero)
        loginButton.setTitle("Log in", for: .normal)
        loginButton.setTitleColor(DebatesListViewController.buttonColor, for: .normal)
        loginButton.titleLabel?.font = UIFont.primaryRegular(14.0)
        return (loginButton, UIBarButtonItem(customView: loginButton))
    }()

    private let accountButton: (button: UIButton, barButton: UIBarButtonItem) = {
        let accountButton = UIButton(frame: .zero)
        accountButton.setTitle("Account", for: .normal)
        accountButton.setTitleColor(DebatesListViewController.buttonColor, for: .normal)
        accountButton.titleLabel?.font = UIFont.primaryRegular(14.0)
        return (accountButton, UIBarButtonItem(customView: accountButton))
    }()

    private let sortByButton: UIButton = {
        let sortByButton = UIButton(frame: .zero)
        sortByButton.setTitle(DebatesListViewController.sortByDefaultlabel, for: .normal)
        sortByButton.setTitleColor(DebatesListViewController.buttonColor, for: .normal)
        sortByButton.titleLabel?.font = UIFont.primaryRegular(16.0)
        return sortByButton
    }()

    private let sortByPickerView = UIPickerView()

    private let searchTextField: UITextField = {
        let searchTextField = UITextField(frame: .zero)
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search...",
                                                                   attributes: [
                                                                    .font : DebatesListViewController.buttonFont as Any,
                                                                    .foregroundColor: DebatesListViewController.buttonColor as Any])
        searchTextField.font = DebatesListViewController.buttonFont
        searchTextField.textColor = DebatesListViewController.selectedColor
        searchTextField.borderStyle = .roundedRect
        return searchTextField
    }()

    private let searchButtonBar: UIToolbar = {
        let searchButtonBar = UIToolbar()
        let searchButton = UIBarButtonItem(title: "Search",
                                           style: .plain,
                                           target: self,
                                           action: #selector(didCompleteSearchInputOrPickerSelection))
        searchButton.tintColor = DebatesListViewController.selectedColor
        searchButton.setTitleTextAttributes([.font : DebatesListViewController.buttonFont as Any], for: .normal)
        searchButtonBar.items = [searchButton]
        searchButtonBar.sizeToFit()
        searchButtonBar.barTintColor = DebatesListViewController.barTintColor
        return searchButtonBar
    }()

    private var searchTextFieldWidth: NSLayoutConstraint?
    private var searchTextFieldTrailing: NSLayoutConstraint?

}

// Gesture recognizer
extension DebatesListViewController {

    // Can't use TapGesture because I need to trigger the instant the user interacts w/ the screen
    // e.g. beginning of scroll, long press, etc.
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.searchTextFieldWidth?.isActive = false
            self?.searchTextFieldTrailing?.isActive = true
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

    // Shrink the text field if it's empty
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                self?.searchTextFieldWidth?.isActive = true
                self?.searchTextFieldTrailing?.isActive = false
                self?.view.layoutIfNeeded()
                }, completion: nil)
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" { // If user clicks enter perform search
            didCompleteSearchInputOrPickerSelection()
            return false
        }
        return true
    }

}

// MARK: View constraints & binding
extension DebatesListViewController {

    private func installViewBinds() {
        searchTextField.delegate = self
        searchTextField.inputAccessoryView = searchButtonBar

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

        view.backgroundColor = .customOffWhite1
        navigationItem.title = "Debates"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black, .font: UIFont.primaryLight(24.0) as Any]
        navigationController?.navigationBar.barTintColor = DebatesListViewController.barTintColor

        userAuthenticationStateChanged(sessionManager.isActive)

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

    // MARK: sortByPickerView UI handling
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

        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.sortByPickerView.alpha = 1.0
        }
    }

    private func removePickerView() {
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            self?.sortByPickerView.alpha = 0.0
            }, completion: { [weak self] _ in // flag not reliable
                self?.sortByPickerView.removeFromSuperview()
        })

    }
}
