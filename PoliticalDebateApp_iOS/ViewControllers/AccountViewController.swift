//
//  AccountViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class AccountViewController: UIViewController, ShiftScrollViewWithKeyboardProtocol {

    required init(viewModel: AccountViewModel) {
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

    // MARK: - Observers & Observables

    private let viewModel: AccountViewModel
    let disposeBag = DisposeBag() // can't be private to satisfy protocol

    // MARK: - Dependencies

    private let sessionManager = SessionManager.shared

    // MARK: - UI Properties

    private static let stackViewSpacing: CGFloat = 32
    private static let horizontalEdgeInset: CGFloat = 56
    var activeTextField: UITextField? { // can't be private to satisfy protocol
        for textField in [newEmailTextField, newPasswordTextField, confirmNewPasswordTextField] where textField.isFirstResponder {
            return textField
        }
        return nil
    }

    // MARK: - UI Elements

    let scrollViewContainer: UIScrollView = { // can't be private to satisfy protocol
        let scrollViewContainer = UIScrollView(frame: .zero)
        return scrollViewContainer
    }()

    private lazy var stackViewContainer: UIStackView = {
        let stackViewContainer = UIStackView(arrangedSubviews: [changeEmailLabel,
                                                                newEmailTextField,
                                                                changePasswordLabel,
                                                                newPasswordTextField,
                                                                confirmNewPasswordTextField,
                                                                submitChangesButton,
                                                                logOutButton,
                                                                deleteAccountButton])
        stackViewContainer.alignment = .center
        stackViewContainer.distribution = .fill
        stackViewContainer.axis = .vertical
        stackViewContainer.spacing = AccountViewController.stackViewSpacing
        stackViewContainer.isLayoutMarginsRelativeArrangement = true
        stackViewContainer.layoutMargins = UIEdgeInsets(top: AccountViewController.stackViewSpacing,
                                                        left: 0,
                                                        bottom: AccountViewController.stackViewSpacing,
                                                        right: 0)
        return stackViewContainer
    }()

    private let changeEmailLabel: UILabel = {
        let changeEmailLabel = UILabel(frame: .zero)
        changeEmailLabel.text = "Change email"
        changeEmailLabel.textColor = GeneralColors.text
        changeEmailLabel.font = GeneralFonts.button
        changeEmailLabel.textAlignment = NSTextAlignment.center
        return changeEmailLabel
    }()

    private let newEmailTextField: UITextField = {
        let emailTextField = UITextField(frame: .zero)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "New email...",
                                                                  attributes: [
                                                                    .font : GeneralFonts.button as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        emailTextField.font = GeneralFonts.button
        emailTextField.textColor = GeneralColors.hardButton
        emailTextField.borderStyle = .roundedRect
        return emailTextField
    }()

    private let changePasswordLabel: UILabel = {
        let passwordLabel = UILabel(frame: .zero)
        passwordLabel.text = "Change password"
        passwordLabel.textColor = GeneralColors.text
        passwordLabel.font = GeneralFonts.button
        passwordLabel.textAlignment = NSTextAlignment.center
        return passwordLabel
    }()

    private let newPasswordTextField: UITextField = {
        let newPasswordTextField = UITextField(frame: .zero)
        newPasswordTextField.attributedPlaceholder = NSAttributedString(string: "New password...",
                                                                        attributes: [
                                                                        .font : GeneralFonts.button as Any,
                                                                        .foregroundColor: GeneralColors.softButton as Any])
        newPasswordTextField.font = GeneralFonts.button
        newPasswordTextField.textColor = GeneralColors.hardButton
        newPasswordTextField.borderStyle = .roundedRect
        newPasswordTextField.isSecureTextEntry = true
        return newPasswordTextField
    }()

    private let confirmNewPasswordTextField: UITextField = {
        let confirmNewPasswordTextField = UITextField(frame: .zero)
        confirmNewPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm new password...",
                                                                               attributes: [
                                                                                .font : GeneralFonts.button as Any,
                                                                                .foregroundColor: GeneralColors.softButton as Any])
        confirmNewPasswordTextField.font = GeneralFonts.button
        confirmNewPasswordTextField.textColor = GeneralColors.hardButton
        confirmNewPasswordTextField.borderStyle = .roundedRect
        confirmNewPasswordTextField.isSecureTextEntry = true
        return confirmNewPasswordTextField
    }()

    private let submitChangesButton: UIButton = {
        let submitChangesButton = UIButton(frame: .zero)
        submitChangesButton.setTitle("Submit changes", for: .normal)
        submitChangesButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        submitChangesButton.titleLabel?.font = GeneralFonts.button
        return submitChangesButton
    }()

    private let logOutButton: UIButton = {
        let logOutButton = UIButton(frame: .zero)
        logOutButton.setTitle("Log out", for: .normal)
        logOutButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        logOutButton.titleLabel?.font = GeneralFonts.button
        return logOutButton
    }()

    private let deleteAccountButton: UIButton = {
        let deleteAccountButton = UIButton(frame: .zero)
        deleteAccountButton.setTitle("Delete account", for: .normal)
        deleteAccountButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        deleteAccountButton.titleLabel?.font = GeneralFonts.button
        return deleteAccountButton
    }()

}

// MARK: - View constraints & binding

extension AccountViewController {

    private func installViewConstraints() {
        navigationItem.title = "Account"
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]

        view.addSubview(scrollViewContainer)
        scrollViewContainer.addSubview(stackViewContainer)

        for subview in stackViewContainer.arrangedSubviews where subview as? UITextField != nil {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor,
                                              constant: -AccountViewController.horizontalEdgeInset).isActive = true
            subview.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor,
                                             constant: AccountViewController.horizontalEdgeInset).isActive = true
        }

        scrollViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false

        scrollViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        scrollViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true
        scrollViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true

        stackViewContainer.topAnchor.constraint(equalTo: scrollViewContainer.topAnchor).isActive = true
        stackViewContainer.trailingAnchor.constraint(equalTo: scrollViewContainer.trailingAnchor).isActive = true
        stackViewContainer.bottomAnchor.constraint(equalTo: scrollViewContainer.bottomAnchor).isActive = true
        stackViewContainer.leadingAnchor.constraint(equalTo: scrollViewContainer.leadingAnchor).isActive = true

        stackViewContainer.widthAnchor.constraint(equalTo: scrollViewContainer.widthAnchor).isActive = true
    }

    private func installViewBinds() {
        logOutButton.addTarget(self, action: #selector(logOutButtonTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        installKeyboardShiftingObserver() // from ShiftScrollViewWithKeyboardProtocol
    }

    @objc private func logOutButtonTapped() {
        sessionManager.logout()
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                        title: "Successfully logged out"))
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteAccountButtonTapped() {
        let confirmationPopUp = UIAlertController(title: "Are you sure?",
                                                  message: "Deleting your account is an irreversible action.",
                                                  preferredStyle: .alert)
        confirmationPopUp.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }

            self.viewModel.deleteAccount().subscribe(onSuccess: { (_) in
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Successfully deleted account"))
                self.sessionManager.logout()
                self.navigationController?.popViewController(animated: true)
            }) { error in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }

                ErrorHandler.showBasicErrorBanner()
            }.disposed(by: self.disposeBag)
        }))
        confirmationPopUp.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        safelyShowAlert(alert: confirmationPopUp)
    }

}
