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

    private let newEmailTextField = BasicUIElementFactory.generateTextField(placeholder: "New email...")

    private let changePasswordLabel = BasicUIElementFactory.generateHeadingLabel(text: "Change password")

    private let currentPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Current password...")

    private let newPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "New password...")

    private let confirmNewPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Confirm new password...")

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
        submitChangesButton.addTarget(self, action: #selector(submitChangesButtonTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutButtonTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        installKeyboardShiftingObserver() // from ShiftScrollViewWithKeyboardProtocol
    }

    @objc private func submitChangesButtonTapped() {
        if let newEmail = newEmailTextField.text,
            newEmail != "" {
            guard EmailAndPasswordValidator.isValidEmail(newEmail) else {
                EmailAndPasswordValidator.showInvalidEmailError()
                return
            }

            // API call

            return
        }
        if (currentPasswordTextField.text != nil && currentPasswordTextField.text != "") ||
            (newPasswordTextField.text != nil && newPasswordTextField.text != "") ||
            (confirmNewPasswordTextField.text != nil && confirmNewPasswordTextField.text != "") {
            guard let currentPassword = currentPasswordTextField.text, currentPassword != "",
                let newPassword = newPasswordTextField.text, newPassword != "",
                let confirmNewPassword = confirmNewPasswordTextField.text, confirmNewPassword != "" else {
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

            // API call

            return
        }

        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: "Please fill in either a new email or new password."))
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

        safelyShowAlert(alert: confirmationPopUp)
    }

}
