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

class LoginOrRegisterViewController: UIViewController, ReactiveKeyboardProtocol {

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
    let disposeBag = DisposeBag() // can't be private to satisfy protocol

    // MARK: - UI Properties

    private static let horizontalEdgeInset: CGFloat = 56
    private let fadeTextAnimation: CATransition = { // for cross-dissolving nav bar title
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.standardAnimationDuration
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

    let scrollViewContainer = UIScrollView(frame: .zero) // can't be private to satisfy protocol

    private lazy var stackViewContainer = BasicUIElementFactory.generateStackViewContainer(arrangedSubviews: [emailLabel,
                                                                                                              emailTextField,
                                                                                                              passwordLabel,
                                                                                                              passwordTextField,
                                                                                                              confirmPasswordTextField,
                                                                                                              submitButton,
                                                                                                              forgotPasswordButton,
                                                                                                              loginOrRegisterButton])

    private let emailLabel = BasicUIElementFactory.generateHeadingLabel(text: "Email")

    private let emailTextField: UITextField = {
        let emailTextField = BasicUIElementFactory.generateTextField(placeholder: "Email...")
        emailTextField.keyboardType = .emailAddress
        return emailTextField
    }()

    private let passwordLabel = BasicUIElementFactory.generateHeadingLabel(text: "Password")

    private let passwordTextField = BasicUIElementFactory.generateTextField(placeholder: "Password...", secureTextEntry: true)

    private let confirmPasswordTextField: UITextField = BasicUIElementFactory.generateTextField(placeholder: "Confirm password...", secureTextEntry: true)

    private let submitButton = BasicUIElementFactory.generateButton(title: "Submit")

    private let forgotPasswordButton = BasicUIElementFactory.generateButton(title: "Forgot password")

    private let loginOrRegisterButton = BasicUIElementFactory.generateButton()

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
        installKeyboardShiftingObserver() // from ReactiveKeyboardProtocol
        installHideKeyboardTapGesture() // from ReactiveKeyboardProtocol
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
                EmailAndPasswordValidator.showInvalidPasswordMatchError()
                return
        }
        viewModel.register(email: email, password: password).subscribe(onSuccess: { [weak self] (_) in
            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                            title: "Registration succeeded. Please check your email for a verification link."))
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

            ErrorHandler.emailUpdateError(response)
        }.disposed(by: disposeBag)
    }

    // swiftlint:disable:next function_body_length
    @objc private func forgotPasswordTapped(forceSend: Bool = false) {
        guard let emailText = emailTextField.text,
            EmailAndPasswordValidator.isValidEmail(emailText) else {
                EmailAndPasswordValidator.showInvalidEmailError()
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
            case BackendErrorMessage.customErrorCode:
                if let backendErrorMessage = try? JSONDecoder().decode(BackendErrorMessage.self, from: response.data) {
                    if backendErrorMessage.messageString.contains(BackendErrorMessage.unverifiedEmailKeyword) {
                        let errorAlert = UIAlertController(title: GeneralCopies.errorAlertTitle,
                                                           message: """
                                                               Your email was never verified.

                                                               Tap 'Force' to try sending the reset link to your unverified email.
                                                           """,
                                                           preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Force", style: .default, handler: { (_) in
                            // self already weakified
                            guard let emailText = self?.emailTextField.text,
                                EmailAndPasswordValidator.isValidEmail(emailText) else {
                                    EmailAndPasswordValidator.showInvalidEmailError()
                                    return
                            }
                            self?.forgotPasswordTapped(forceSend: true)
                        }))
                        errorAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                        safelyShowAlert(alert: errorAlert)
                        return
                    } else if backendErrorMessage.messageString.contains(BackendErrorMessage.invalidEmailKeyword) {
                        NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                        title: "Verification link couldn't be sent to the given email."))
                        return
                    }
                }
                ErrorHandler.showBasicErrorBanner()
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
            let shouldShowConfirmPasswordField = newState == .register
            let shouldAnimate = newLoginOrRegisterState.animated

            UIView.animate(withDuration: shouldAnimate ? Constants.standardAnimationDuration : 0.0, animations: {
                self.confirmPasswordTextField.isHidden = !shouldShowConfirmPasswordField
                self.confirmPasswordTextField.alpha = shouldShowConfirmPasswordField ? 1.0 : 0.0
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
