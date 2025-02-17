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

    // MARK: - Observers & Observables

    private let viewModel: AccountViewModel
    let disposeBag = DisposeBag() // can't be private to satisfy protocol

    // MARK: - UI Properties

    private static let textFieldHorizontalInset: CGFloat = 56
    var activeTextField: UITextField? { // can't be private to satisfy protocol
        for textField in [newEmailTextField, currentPasswordTextField, newPasswordTextField, confirmNewPasswordTextField] where textField.isFirstResponder {
            return textField
        }
        return nil
    }
    private static let changeEmailLabelText = "Change email"

    // MARK: - UI Elements

    lazy var scrollViewContainer = UIScrollView(frame: .zero) // can't be private so as to satisfy the KeyboardReactable protocol

    private lazy var stackViewContainer = BasicUIElementFactory.generateStackViewContainer(arrangedSubviews: [changeEmailLabel,
                                                                                                              newEmailTextField,
                                                                                                              changePasswordLabel,
                                                                                                              currentPasswordTextField,
                                                                                                              newPasswordTextField,
                                                                                                              confirmNewPasswordTextField,
                                                                                                              submitChangesButton,
                                                                                                              logOutButton,
                                                                                                              deleteAccountButton,
                                                                                                              complianceTextView,
                                                                                                              versionLabel])

    private lazy var changeEmailLabel = BasicUIElementFactory.generateLabel(text: Self.changeEmailLabelText, textAlignment: .center)

    private lazy var newEmailTextField = BasicUIElementFactory.generateTextField(placeholder: "New email...",
                                                                                 keyboardType: .emailAddress,
                                                                                 returnKeyType: .go,
                                                                                 delegate: self)

    private lazy var changePasswordLabel = BasicUIElementFactory.generateLabel(text: "Change password", textAlignment: .center)

    private lazy var currentPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Current password...",
                                                                                        secureTextEntry: true,
                                                                                        returnKeyType: .go,
                                                                                        delegate: self)

    private lazy var newPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "New password...",
                                                                                    secureTextEntry: true,
                                                                                    returnKeyType: .go,
                                                                                    delegate: self)

    private lazy var confirmNewPasswordTextField = BasicUIElementFactory.generateTextField(placeholder: "Confirm new password...",
                                                                                           secureTextEntry: true,
                                                                                           returnKeyType: .go,
                                                                                           delegate: self)

    private lazy var submitChangesButton = BasicUIElementFactory.generateButton(title: "Submit changes")

    private lazy var logOutButton = BasicUIElementFactory.generateButton(title: "Log out")

    private lazy var deleteAccountButton = BasicUIElementFactory.generateButton(title: "Delete account")

    private lazy var complianceTextView = BasicUIElementFactory.generateComplianceTextView(login: false)

    private lazy var versionLabel = BasicUIElementFactory.generateVersionLabel()

}

// MARK: - View constraints & binding

extension AccountViewController {

    private func installViewConstraints() {
        navigationItem.title = "Account"
        navigationController?.navigationBar.tintColor = GeneralColors.navBarButton
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle]
        view.backgroundColor = GeneralColors.background

        view.addSubview(scrollViewContainer)
        scrollViewContainer.addSubview(stackViewContainer)

        for subview in stackViewContainer.arrangedSubviews where subview as? UITextField != nil {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor,
                                             constant: Self.textFieldHorizontalInset).isActive = true
            subview.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor,
                                              constant: -Self.textFieldHorizontalInset).isActive = true
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

    private func updateEmailLabel(with email: String) {
        UIView.transition(with: changeEmailLabel, duration: GeneralConstants.standardAnimationDuration, options: .transitionCrossDissolve, animations: {
            self.changeEmailLabel.text = "\(Self.changeEmailLabelText) (\(email))"
        }, completion: nil)
    }

    private func installViewBinds() {
        getCurrentEmail()
        submitChangesButton.addTarget(self, action: #selector(submitChangesButtonTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutButtonTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountButtonTapped), for: .touchUpInside)
        installKeyboardShiftingObserver() // from KeyboardReactable
        installHideKeyboardTapGesture() // from KeyboardReactable
        complianceTextView.delegate = self
    }

    private func getCurrentEmail() {
        viewModel.getCurrentEmail()
            .map(CurrentEmail.self)
            .subscribe(onSuccess: { [weak self] currentEmail in
                self?.updateEmailLabel(with: currentEmail.email)
                if !currentEmail.isVerified {
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Your email is unverified.",
                                                                                                    subtitle: "You won't be able to reset your password.",
                                                                                                    duration: .seconds(seconds: 3),
                                                                                                    buttonConfig: .customTitle(title: "Resend link", action: {
                                                                                                        self?.requestVerificationLink()
                                                                                                    })
                    ))
                }
            }) { ErrorHandlerService.handleRequest(error: $0, withMessage: "Couldn't retrieve your current email.") }
            .disposed(by: disposeBag)
    }

    private func requestVerificationLink() {
        viewModel.requestVerificationLink().subscribe(onSuccess: { _ in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Successfully sent verification link."))
        }) { ErrorHandlerService.handleRequestBackendMessage(from: $0) }
            .disposed(by: disposeBag)
    }

    // swiftlint:disable:next function_body_length
    @objc private func submitChangesButtonTapped() {
        var allFieldsEmpty = true

        if let newEmail = newEmailTextField.text,
            !newEmail.isEmpty {
            allFieldsEmpty = false

            guard EmailAndPasswordValidator.isValidEmail(newEmail) else {
                ErrorHandlerService.showInvalidEmailError()
                return
            }

            viewModel.changeEmail(to: newEmail).subscribe(onSuccess: { [weak self] _ in
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                      title: "Email change succeeded.",
                                                                      subtitle: "Please check your email for a verification link."))
                self?.newEmailTextField.text = nil
                self?.updateEmailLabel(with: newEmail)
            }) { ErrorHandlerService.handleRequestBackendMessage(from: $0) }
                .disposed(by: disposeBag)
        }
        if (!(currentPasswordTextField.text?.isEmpty ?? true) ||
            !(newPasswordTextField.text?.isEmpty ?? true) ||
            !(confirmNewPasswordTextField.text?.isEmpty ?? true)) {
            allFieldsEmpty = false

            guard let currentPassword = currentPasswordTextField.text, !currentPassword.isEmpty,
                let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
                let confirmNewPassword = confirmNewPasswordTextField.text, !confirmNewPassword.isEmpty else {
                    NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                    title: "Please fill in either all or none of the password fields."))
                    return
            }
            guard EmailAndPasswordValidator.isValidPassword(currentPassword) &&
            EmailAndPasswordValidator.isValidPassword(newPassword) else {
                ErrorHandlerService.showInvalidPasswordError()
                return
            }
            guard newPassword == confirmNewPassword else {
                ErrorHandlerService.showInvalidPasswordMatchError()
                return
            }

            viewModel.changePassword(from: currentPassword, to: newPassword).subscribe(onSuccess: { [weak self] _ in
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Password change succeeded."))
                self?.currentPasswordTextField.text = nil
                self?.newPasswordTextField.text = nil
                self?.confirmNewPasswordTextField.text = nil
            }) { ErrorHandlerService.handleRequestBackendMessage(from: $0) }
                .disposed(by: disposeBag)
        }

        if allFieldsEmpty {
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: "Please fill in either a new email or new password."))
        }
    }

    @objc private func logOutButtonTapped() {
        SessionManager.shared.logout()
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                        title: "Successfully logged out."))
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteAccountButtonTapped() {
        let confirmationPopUp = UIAlertController(title: "Are you sure?",
                                                  message: "Deleting your account is an irreversible action.",
                                                  preferredStyle: .alert)
        confirmationPopUp.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }

            self.viewModel.deleteAccount().subscribe(onSuccess: { _ in
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Successfully deleted account."))
                SessionManager.shared.logout()
                self.navigationController?.popViewController(animated: true)
            }) { ErrorHandlerService.handleRequest(error: $0) }
                .disposed(by: self.disposeBag)
        }))
        confirmationPopUp.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        self.present(confirmationPopUp, animated: true)
    }

}

// MARK: - UITextViewDelegate

extension AccountViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        navigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}

// MARK: - UITextFieldDelegate

extension AccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" { // If user clicks enter submit
            submitChangesButtonTapped()
            return false
        }
        return true
    }
}
