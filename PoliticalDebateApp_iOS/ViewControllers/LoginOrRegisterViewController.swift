//
//  LoginOrRegisterViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import Moya
import RxCocoa
import RxSwift
import UIKit

class LoginOrRegisterViewController: UIViewController, KeyboardReactable {

    required init(viewModel: LoginOrRegisterViewModel) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showInfoAlertIfNeeded()
    }

    // MARK: - Observers & Observables

    private let viewModel: LoginOrRegisterViewModel
    let disposeBag = DisposeBag() // can't be private to satisfy protocol

    // MARK: - UI Properties

    private static let textFieldHorizontalInset: CGFloat = 56
    private let fadeTextAnimation: CATransition = { // for cross-dissolving nav bar title
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = GeneralConstants.standardAnimationDuration
        fadeTextAnimation.type = CATransitionType.fade
        return fadeTextAnimation
    }()
    var activeTextField: UITextField? { // can't be private to satisfy protocol
        for textField in [emailTextField, passwordTextField, confirmPasswordTextField] where textField.isFirstResponder {
            return textField
        }
        return nil
    }

    // MARK: - UI Elements

    private let infoButton: (button: UIButton, barButton: UIBarButtonItem) = {
        let infoButton = UIButton(type: .infoLight)
        return (infoButton, UIBarButtonItem(customView: infoButton))
    }()

    let scrollViewContainer = UIScrollView(frame: .zero) // can't be private to satisfy protocol

    private lazy var stackViewContainer = BasicUIElementFactory.generateStackViewContainer(arrangedSubviews: [emailLabel,
                                                                                                              emailTextField,
                                                                                                              passwordLabel,
                                                                                                              passwordTextField,
                                                                                                              confirmPasswordTextField,
                                                                                                              submitButton,
                                                                                                              forgotPasswordButton,
                                                                                                              loginOrRegisterButton,
                                                                                                              complianceTextView,
                                                                                                              versionLabel])

    private let emailLabel = BasicUIElementFactory.generateHeadingLabel(text: "Email")

    private lazy var emailTextField = BasicUIElementFactory.generateTextField(placeholder: "Email...",
                                                                              keyboardType: .emailAddress,
                                                                              returnKeyType: .go,
                                                                              delegate: self)

    private let passwordLabel = BasicUIElementFactory.generateHeadingLabel(text: "Password")

    private lazy var passwordTextField = BasicUIElementFactory.generateTextField(placeholder: "Password...",
                                                                                 secureTextEntry: true,
                                                                                 returnKeyType: .go,
                                                                                 delegate: self)

    private lazy var confirmPasswordTextField: UITextField = BasicUIElementFactory.generateTextField(placeholder: "Confirm password...",
                                                                                                     secureTextEntry: true,
                                                                                                     returnKeyType: .go,
                                                                                                     delegate: self)

    private lazy var submitButton = BasicUIElementFactory.generateButton(title: "Submit")

    private lazy var forgotPasswordButton = BasicUIElementFactory.generateButton(title: "Forgot password")

    private lazy var loginOrRegisterButton = BasicUIElementFactory.generateButton()

    private lazy var complianceTextView = BasicUIElementFactory.generateComplianceTextView(login: true)

    private lazy var versionLabel = BasicUIElementFactory.generateVersionLabel()

}

// MARK: - View constraints & binding

extension LoginOrRegisterViewController {

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.navBarButton
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle]
        navigationItem.rightBarButtonItem = infoButton.barButton
        view.backgroundColor = GeneralColors.background

        view.addSubview(scrollViewContainer)
        scrollViewContainer.addSubview(stackViewContainer)

        for subview in stackViewContainer.arrangedSubviews where subview as? UITextField != nil {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor,
                                              constant: -Self.textFieldHorizontalInset).isActive = true
            subview.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor,
                                             constant: Self.textFieldHorizontalInset).isActive = true
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
        infoButton.button.addTarget(self, action: #selector(showInfoAlert), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        installLoginOrRegisterButtonBinds()
        installKeyboardShiftingObserver() // from KeyboardReactable
        installHideKeyboardTapGesture() // from KeyboardReactable
        complianceTextView.delegate = self
    }

    private func showInfoAlertIfNeeded() {
        guard !UserDefaultsService.hasSeenRegisterInfoAlert else { return }

        UserDefaultsService.hasSeenRegisterInfoAlert = true
        showInfoAlert()
    }

    @objc private func showInfoAlert() {
        let infoAlert = UIAlertController(title: "Heads up",
                                          message: """
                                                               The ONLY reason to make an account is to sync your data (progress, starred, etc.) between web and mobile.

                                                               We only use your email to reset your password. You will never receive any other mailing from us.
                                                           """,
                                          preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: "Got it", style: .cancel, handler: nil))
        present(infoAlert, animated: true)
    }

    @objc private func submitButtonTapped() {
        guard let emailText = emailTextField.text,
            EmailAndPasswordValidator.isValidEmail(emailText) else {
                EmailAndPasswordValidator.showInvalidEmailError()
                return
        }
        guard let passwordText = passwordTextField.text,
            EmailAndPasswordValidator.isValidPassword(passwordText) else {
                EmailAndPasswordValidator.showInvalidPasswordError()
                return
        }
        switch viewModel.loginOrRegisterStateRelay.value.state {
        case .login:
            loginTapped(email: emailText, password: passwordText)
        case .register:
            registerTapped(email: emailText, password: passwordText)
        }
    }

    private func loginTapped(email: String, password: String) {
        viewModel.login(with: email, password: password).subscribe(onSuccess: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }) { error in
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
            case 401,
                 404:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't find an account associated with those credentials."))
            case _ where GeneralConstants.retryErrorCodes.contains(response.statusCode):
                ErrorHandlerService.showBasicRetryErrorBanner { [weak self] in
                    self?.loginTapped(email: email, password: password)
                }
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }.disposed(by: disposeBag)
    }

    private func registerTapped(email: String, password: String) {
        guard let confirmPasswordText = confirmPasswordTextField.text,
            confirmPasswordText == password else {
                EmailAndPasswordValidator.showInvalidPasswordMatchError()
                return
        }
        viewModel.register(email: email, password: password).subscribe(onSuccess: { [weak self] _ in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Registration succeeded.",
                                                                                            subtitle: "Please check your email for a verification link."))
            self?.loginTapped(email: email, password: password) // log the user in after registering
        }) { error in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard let moyaError = error as? MoyaError,
                let response = moyaError.response else {
                    ErrorHandlerService.showBasicRetryErrorBanner()
                    return
            }

            ErrorHandlerService.emailUpdateError(response)
        }.disposed(by: disposeBag)
    }

    // swiftlint:disable:next function_body_length
    @objc private func forgotPasswordTapped(forceSend: Bool = false) {
        guard let emailText = emailTextField.text,
            EmailAndPasswordValidator.isValidEmail(emailText) else {
                EmailAndPasswordValidator.showInvalidEmailError()
                return
        }

        viewModel.forgotPassword(email: emailText, forceSend: forceSend).subscribe(onSuccess: { _ in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Please check your email for a password reset link.",
                                                                                            duration: .forever))
        }, onError: { [weak self] error in
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
                if let backendErrorMessage = try? JSONDecoder().decode(BackendErrorMessage.self, from: response.data) {
                    if backendErrorMessage.messageString.contains(BackendErrorMessage.unverifiedEmailKeyword) {
                        let errorAlert = UIAlertController(title: GeneralCopies.errorAlertTitle,
                                                           message: """
                                                               Your email was never verified.

                                                               Tap 'Force' to try sending the reset link to your unverified email.
                                                           """,
                                                           preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Force", style: .default, handler: { _ in
                            // self already weakified
                            guard let emailText = self?.emailTextField.text,
                                EmailAndPasswordValidator.isValidEmail(emailText) else {
                                    EmailAndPasswordValidator.showInvalidEmailError()
                                    return
                            }
                            self?.forgotPasswordTapped(forceSend: true)
                        }))
                        errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                        self?.present(errorAlert, animated: true)
                        return
                    } else if backendErrorMessage.messageString.contains(BackendErrorMessage.invalidEmailKeyword) {
                        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                        title: "Verification link couldn't be sent to the given email."))
                        return
                    }
                }
                ErrorHandlerService.showBasicReportErrorBanner()
            case 404:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't find an account associated with that email."))
            default:
                ErrorHandlerService.showBasicRetryErrorBanner()
            }
        }).disposed(by: self.disposeBag)
    }

    private func installLoginOrRegisterButtonBinds() {

        loginOrRegisterButton.addTarget(self, action: #selector(loginOrRegisterButtonTapped), for: .touchUpInside)

        viewModel.loginOrRegisterStateRelay.subscribe(onNext: { [weak self] newLoginOrRegisterState in
            guard let self = self else {
                    return
            }

            let newState = newLoginOrRegisterState.state
            let shouldShowConfirmPasswordField = newState == .register
            let shouldAnimate = newLoginOrRegisterState.animated

            UIView.animate(withDuration: shouldAnimate ? GeneralConstants.standardAnimationDuration : 0.0, animations: {
                if shouldShowConfirmPasswordField { self.infoButton.button.isHidden = !shouldShowConfirmPasswordField }
                self.infoButton.button.alpha = shouldShowConfirmPasswordField ? 1.0 : 0.0
                self.confirmPasswordTextField.isHidden = !shouldShowConfirmPasswordField
                self.confirmPasswordTextField.alpha = shouldShowConfirmPasswordField ? 1.0 : 0.0

                self.navigationController?.navigationBar.layer.add(self.fadeTextAnimation, forKey: "fadeText")
                self.navigationItem.title = newState.rawValue

            }) { _ in // flag not reliable
                UIView.transition(with: self.loginOrRegisterButton,
                                  duration: shouldAnimate ? GeneralConstants.standardAnimationDuration : 0.0,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.loginOrRegisterButton.setTitle(newState.otherState.rawValue, for: .normal)
                },
                                  completion: nil)

                // In case we just animated the alpha to 0
                self.infoButton.button.isHidden = !shouldShowConfirmPasswordField
            }
        }).disposed(by: disposeBag)
    }

    @objc private func loginOrRegisterButtonTapped() {
        viewModel.loginOrRegisterStateRelay.accept((self.viewModel.loginOrRegisterStateRelay.value.state.otherState, true))
    }
}

// MARK: - UITextViewDelegate

extension LoginOrRegisterViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        navigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}

// MARK: - UITextFieldDelegate

extension LoginOrRegisterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" { // If user clicks enter submit
            submitButtonTapped()
            return false
        }
        return true
    }
}
