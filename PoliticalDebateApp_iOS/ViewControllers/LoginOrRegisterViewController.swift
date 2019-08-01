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

class LoginOrRegisterViewController: UIViewController {

    required init(viewModel: LoginOrRegisterViewModel) {
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

    private let viewModel: LoginOrRegisterViewModel
    private let disposeBag = DisposeBag()

    // MARK: - Helpers

    private static func isValidEmail(_ email: String) -> Bool {
        let firstPart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
        let serverPart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
        let emailRegex = firstPart + "@" + serverPart + "[A-Za-z]{2,8}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private static func isValidPassword(_ password: String) -> Bool {
        return password.count >= Constants.minimumPasswordLength
    }

    private static func showInvalidEmailError() {
        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                        title: "Please provide a proper email"))
    }

    // MARK: - UI Properties

    private static let stackViewSpacing: CGFloat = 32
    private static let horizontalEdgeInset: CGFloat = 56
    private let fadeTextAnimation: CATransition = {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.standardAnimationDuration
        fadeTextAnimation.type = CATransitionType.fade
        return fadeTextAnimation
    }()

    // MARK: - UI Elements

    private let scrollViewContainer: UIScrollView = {
        let scrollViewContainer = UIScrollView(frame: .zero)
        return scrollViewContainer
    }()

    private lazy var stackViewContainer: UIStackView = {
        let stackViewContainer = UIStackView(arrangedSubviews: [emailLabel,
                                                                emailTextField,
                                                                passwordLabel,
                                                                passwordTextField,
                                                                confirmPasswordLabel,
                                                                confirmPasswordTextField,
                                                                submitButton,
                                                                forgotPasswordButton,
                                                                loginOrRegisterButton])
        stackViewContainer.alignment = .center
        stackViewContainer.distribution = .fill
        stackViewContainer.axis = .vertical
        stackViewContainer.spacing = LoginOrRegisterViewController.stackViewSpacing
        stackViewContainer.isLayoutMarginsRelativeArrangement = true
        stackViewContainer.layoutMargins = UIEdgeInsets(top: LoginOrRegisterViewController.stackViewSpacing,
                                                        left: 0,
                                                        bottom: LoginOrRegisterViewController.stackViewSpacing,
                                                        right: 0)
        return stackViewContainer
    }()

    private let emailLabel: UILabel = {
        let emailLabel = UILabel(frame: .zero)
        emailLabel.text = "Email"
        emailLabel.textColor = GeneralColors.text
        emailLabel.font = GeneralFonts.button
        emailLabel.textAlignment = NSTextAlignment.center
        return emailLabel
    }()

    private let emailTextField: UITextField = {
        let emailTextField = UITextField(frame: .zero)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email...",
                                                                  attributes: [
                                                                    .font : GeneralFonts.button as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        emailTextField.font = GeneralFonts.button
        emailTextField.textColor = GeneralColors.hardButton
        emailTextField.borderStyle = .roundedRect
        return emailTextField
    }()

    private let passwordLabel: UILabel = {
        let passwordLabel = UILabel(frame: .zero)
        passwordLabel.text = "Password"
        passwordLabel.textColor = GeneralColors.text
        passwordLabel.font = GeneralFonts.button
        passwordLabel.textAlignment = NSTextAlignment.center
        return passwordLabel
    }()

    private let passwordTextField: UITextField = {
        let passwordTextField = UITextField(frame: .zero)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password...",
                                                                     attributes: [
                                                                    .font : GeneralFonts.button as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        passwordTextField.font = GeneralFonts.button
        passwordTextField.textColor = GeneralColors.hardButton
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        return passwordTextField
    }()

    private let confirmPasswordLabel: UILabel = {
        let confirmPasswordLabel = UILabel(frame: .zero)
        confirmPasswordLabel.text = "Confirm password"
        confirmPasswordLabel.textColor = GeneralColors.text
        confirmPasswordLabel.font = GeneralFonts.button
        confirmPasswordLabel.textAlignment = NSTextAlignment.center
        return confirmPasswordLabel
    }()

    private let confirmPasswordTextField: UITextField = {
        let confirmPasswordTextField = UITextField(frame: .zero)
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password...",
                                                                            attributes: [
                                                                    .font : GeneralFonts.button as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        confirmPasswordTextField.font = GeneralFonts.button
        confirmPasswordTextField.textColor = GeneralColors.hardButton
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.isSecureTextEntry = true
        return confirmPasswordTextField
    }()

    private let submitButton: UIButton = {
        let submitButton = UIButton(frame: .zero)
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        submitButton.titleLabel?.font = GeneralFonts.button
        return submitButton
    }()

    private let forgotPasswordButton: UIButton = {
        let forgotPasswordButton = UIButton(frame: .zero)
        forgotPasswordButton.setTitle("Forgot password", for: .normal)
        forgotPasswordButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        forgotPasswordButton.titleLabel?.font = GeneralFonts.button
        return forgotPasswordButton
    }()

    private let loginOrRegisterButton: UIButton = {
        let loginOrRegisterButton = UIButton(frame: .zero)
        loginOrRegisterButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        loginOrRegisterButton.titleLabel?.font = GeneralFonts.button
        return loginOrRegisterButton
    }()

}

// MARK: - View constraints & binding

extension LoginOrRegisterViewController {

    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]

        view.addSubview(scrollViewContainer)
        scrollViewContainer.addSubview(stackViewContainer)

        for subview in stackViewContainer.arrangedSubviews where subview as? UITextField != nil {
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.trailingAnchor.constraint(equalTo: stackViewContainer.trailingAnchor,
                                              constant: -LoginOrRegisterViewController.horizontalEdgeInset).isActive = true
            subview.leadingAnchor.constraint(equalTo: stackViewContainer.leadingAnchor,
                                             constant: LoginOrRegisterViewController.horizontalEdgeInset).isActive = true
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
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        installLoginOrRegisterButtonBinds()
    }

    @objc private func submitButtonTapped() {
        guard let emailText = emailTextField.text,
            LoginOrRegisterViewController.isValidEmail(emailText) else {
                LoginOrRegisterViewController.showInvalidEmailError()
                return
        }
        guard let passwordText = passwordTextField.text,
            LoginOrRegisterViewController.isValidPassword(passwordText) else {
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                      title: "Password must be at least \(Constants.minimumPasswordLength) characters."))
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
        viewModel.login(email: email, password: password).subscribe(onSuccess: { [weak self] _ in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Successfully logged in"))
            self?.navigationController?.popViewController(animated: true)
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
            case 401,
                 404:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't find an account associated with those credentials."))
            default:
                ErrorHandler.showBasicErrorBanner()
            }
        }.disposed(by: disposeBag)
    }

    private func registerTapped(email: String, password: String) {
        guard let confirmPasswordText = confirmPasswordTextField.text,
            confirmPasswordText == password else {
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Passwords do not match."))
                return
        }
        viewModel.register(email: email, password: password).subscribe(onSuccess: { [weak self] (_) in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Registration succeeded."))
            self?.loginTapped(email: email, password: password) // log the user in after registering
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
            case 400:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Verification link couldn't be sent to the given email."))
            case 500:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "An account associated with that email already exists."))
            default:
                ErrorHandler.showBasicErrorBanner()
            }
        }.disposed(by: disposeBag)
    }

    @objc private func forgotPasswordTapped(forceSend: Bool = false) {
        guard let emailText = emailTextField.text,
            LoginOrRegisterViewController.isValidEmail(emailText) else {
                LoginOrRegisterViewController.showInvalidEmailError()
                return
        }

        viewModel.forgotPassword(email: emailText, forceSend: forceSend).subscribe(onSuccess: { (_) in
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
                    ErrorHandler.showBasicErrorBanner()
                    return
            }
            switch response.statusCode {
            case Constants.customBackendErrorMessageCode:
                let errorAlert = UIAlertController(title: GeneralCopies.errorAlertTitle,
                                                   message: """
                                                               Either your email is invalid or it was not verified.

                                                               Tap 'Force' to try sending the reset link to an unverified email.
                                                           """,
                                                   preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Force", style: .default, handler: { (_) in
                    // self already weakified
                    guard let emailText = self?.emailTextField.text,
                        LoginOrRegisterViewController.isValidEmail(emailText) else {
                            LoginOrRegisterViewController.showInvalidEmailError()
                            return
                    }
                    self?.forgotPasswordTapped(forceSend: true)
                }))
                errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                safelyShowAlert(alert: errorAlert)
            case 404:
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                title: "Couldn't find an account associated with that email."))
            default:
                ErrorHandler.showBasicErrorBanner()
            }
        }).disposed(by: self.disposeBag)
    }

    private func installLoginOrRegisterButtonBinds() {

        loginOrRegisterButton.addTarget(self, action: #selector(loginOrRegisterButtonTapped), for: .touchUpInside)

        viewModel.loginOrRegisterStateRelay.subscribe { [weak self] (newStateEvent) in
            guard let newLoginOrRegisterState = newStateEvent.element,
                let self = self else {
                    return
            }

            let newState = newLoginOrRegisterState.state
            let shouldShowConfirmPasswordFields = newState == .register
            let shouldAnimate = newLoginOrRegisterState.animated

            self.navigationController?.navigationBar.layer.add(self.fadeTextAnimation, forKey: "fadeText")

            UIView.animate(withDuration: shouldAnimate ? Constants.standardAnimationDuration : 0.0, animations: {
                self.confirmPasswordLabel.isHidden = !shouldShowConfirmPasswordFields
                self.confirmPasswordTextField.isHidden = !shouldShowConfirmPasswordFields
                self.confirmPasswordLabel.alpha = shouldShowConfirmPasswordFields ? 1.0 : 0.0
                self.confirmPasswordTextField.alpha = shouldShowConfirmPasswordFields ? 1.0 : 0.0
            }) { _ in // flag not reliable
                self.navigationController?.navigationBar.layer.add(self.fadeTextAnimation, forKey: "fadeText")
                self.navigationItem.title = newState.rawValue
                UIView.transition(with: self.loginOrRegisterButton,
                                  duration: shouldAnimate ? Constants.standardAnimationDuration : 0.0,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.loginOrRegisterButton.setTitle(newState.otherState.rawValue, for: .normal)
                },
                                  completion: nil)
            }
            }.disposed(by: disposeBag)
    }

    @objc private func loginOrRegisterButtonTapped() {
        viewModel.loginOrRegisterStateRelay.accept((self.viewModel.loginOrRegisterStateRelay.value.state.otherState, true))
    }

}
