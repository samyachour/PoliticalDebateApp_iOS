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

class AccountViewController: UIViewController, KeyboardReactable {

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

    private static let horizontalEdgeInset: CGFloat = 56
    var activeTextField: UITextField? { // can't be private to satisfy protocol
        for textField in [newEmailTextField, currentPasswordTextField, newPasswordTextField, confirmNewPasswordTextField] where textField.isFirstResponder {
            return textField
        }
        return nil
    }

    // MARK: - UI Elements

    let scrollViewContainer = UIScrollView(frame: .zero) // can't be private to satisfy protocol

    private lazy var stackViewContainer = BasicUIElementFactory.generateStackViewContainer(arrangedSubviews: [changeEmailLabel,
                                                                                                              newEmailTextField,
                                                                                                              changePasswordLabel,
                                                                                                              currentPasswordTextField,
                                                                                                              newPasswordTextField,
                                                                                                              confirmNewPasswordTextField,
                                                                                                              submitChangesButton,
                                                                                                              logOutButton,
                                                                                                              deleteAccountButton])

    private let changeEmailLabel = BasicUIElementFactory.generateHeadingLabel(text: "Change email")

    private let newEmailTextField: UITextField = {
        let newEmailTextField = BasicUIElementFactory.generateTextField(placeholder: "New email...")
        newEmailTextField.keyboardType = .emailAddress
        return newEmailTextField
    }()

    private let changePasswordLabel = BasicUIElementFactory.generateHeadingLabel(text: "Change password")

    private let currentPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Current password...", secureTextEntry: true)

    private let newPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "New password...", secureTextEntry: true)

    private let confirmNewPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Confirm new password...", secureTextEntry: true)

    private let submitChangesButton = BasicUIElementFactory.generateButton(title: "Submit changes")

    private let logOutButton = BasicUIElementFactory.generateButton(title: "Log out")

    private let deleteAccountButton = BasicUIElementFactory.generateButton(title: "Delete account")

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
            subview.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor,
                                             constant: AccountViewController.horizontalEdgeInset).isActive = true
            subview.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor,
                                              constant: -AccountViewController.horizontalEdgeInset).isActive = true
        }

        scrollViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false

        scrollViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollViewContainer.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        scrollViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollViewContainer.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).isActive = true

        stackViewContainer.leadingAnchor.constraint(equalTo: scrollViewContainer.leadingAnchor).isActive = true
        stackViewContainer.topAnchor.constraint(equalTo: scrollViewContainer.topAnchor).isActive = true
        stackViewContainer.trailingAnchor.constraint(equalTo: scrollViewContainer.trailingAnchor).isActive = true
        stackViewContainer.bottomAnchor.constraint(equalTo: scrollViewContainer.bottomAnchor).isActive = true

        stackViewContainer.widthAnchor.constraint(equalTo: scrollViewContainer.widthAnchor).isActive = true
    }

    private func installViewBinds() {
        submitChangesButton.addTarget(self, action: #selector(submitChangesButtonTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutButtonTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        installKeyboardShiftingObserver() // from KeyboardReactable
        installHideKeyboardTapGesture() // from KeyboardReactable
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    @objc private func submitChangesButtonTapped() {
        var allFieldsEmpty = true

        if let newEmail = newEmailTextField.text,
            !newEmail.isEmpty {
            allFieldsEmpty = false

            guard EmailAndPasswordValidator.isValidEmail(newEmail) else {
                EmailAndPasswordValidator.showInvalidEmailError()
                return
            }

            viewModel.changeEmail(to: newEmail).subscribe(onSuccess: { [weak self] (_) in
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                      title: "Email change succeeded. Please check your email for a verification link."))
                self?.newEmailTextField.text = nil
            }) { error in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }
                guard let moyaError = error as? MoyaError,
                    let response = moyaError.response else {
                        ErrorHandler.showBasicErrorBanner()
                        return
                }

                ErrorHandler.emailUpdateError(response)
            }.disposed(by: disposeBag)
        }
        if (!(currentPasswordTextField.text?.isEmpty ?? true) ||
            !(newPasswordTextField.text?.isEmpty ?? true) ||
            !(confirmNewPasswordTextField.text?.isEmpty ?? true)) {
            allFieldsEmpty = false

            guard let currentPassword = currentPasswordTextField.text, !currentPassword.isEmpty,
                let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
                let confirmNewPassword = confirmNewPasswordTextField.text, !confirmNewPassword.isEmpty else {
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Please fill in either all of or none of the password fields."))
                    return
            }
            guard EmailAndPasswordValidator.isValidPassword(currentPassword) &&
            EmailAndPasswordValidator.isValidPassword(newPassword) else {
                EmailAndPasswordValidator.showInvalidPasswordError()
                return
            }
            guard newPassword == confirmNewPassword else {
                EmailAndPasswordValidator.showInvalidPasswordMatchError()
                return
            }

            viewModel.changePassword(from: currentPassword, to: newPassword).subscribe(onSuccess: { [weak self] (_) in
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Password change succeeded."))
                self?.currentPasswordTextField.text = nil
                self?.newPasswordTextField.text = nil
                self?.confirmNewPasswordTextField.text = nil
            }) { error in
                if let generalError = error as? GeneralError,
                    generalError == .alreadyHandled {
                    return
                }
                guard let moyaError = error as? MoyaError,
                    let response = moyaError.response else {
                        ErrorHandler.showBasicErrorBanner()
                        return
                }

                switch response.statusCode {
                case BackendErrorMessage.customErrorCode:
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Your current password is incorrect."))
                default:
                    ErrorHandler.showBasicErrorBanner()
                }
            }.disposed(by: disposeBag)
        }

        if allFieldsEmpty {
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: "Please fill in either a new email or new password."))
        }
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
                                                                                                title: "Successfully deleted account."))
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

        self.present(confirmationPopUp, animated: true)
    }

}
