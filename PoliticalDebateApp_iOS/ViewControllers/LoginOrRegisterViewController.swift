//
//  LoginOrRegisterViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

public class LoginOrRegisterViewController: UIViewController {

    public required init(viewModel: LoginOrRegisterViewModel) {
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
        hideConfirmPasswordField(immediately: true)
    }

    // MARK: Dependencies
    private let sessionManager = SessionManager.shared

    // MARK: Observers & Observables

    private let viewModel: LoginOrRegisterViewModel

    // MARK: Action handlers

    @objc private func loginOrRegisterButtonPressed() {
        switch viewModel.loginOrRegisterState {
        case .login:
            showConfirmPasswordField()
        case .register:
            hideConfirmPasswordField()
        }
    }

    // MARK: UI Properties

    private static let labelToTextFieldDistance: CGFloat = 16
    private static let fieldDistance: CGFloat = 32
    private static let textFieldToEdgeDistance: CGFloat = 56
    private var submitButtonTopToPassword: NSLayoutConstraint?
    private var submitButtonTopToConfirmPassword: NSLayoutConstraint?
    private let fadeTextAnimation: CATransition = {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = Constants.standardAnimationDuration
        fadeTextAnimation.type = CATransitionType.fade
        return fadeTextAnimation
    }()

    // MARK: UI Elements

    private let emailLabel: UILabel = {
        let emailLabel = UILabel(frame: .zero)
        emailLabel.text = "Email"
        emailLabel.textColor = GeneralColors.text
        emailLabel.font = GeneralFonts.buttonFont
        emailLabel.textAlignment = NSTextAlignment.center
        return emailLabel
    }()

    private let emailTextField: UITextField = {
        let emailTextField = UITextField(frame: .zero)
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email...",
                                                                  attributes: [
                                                                    .font : GeneralFonts.buttonFont as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        emailTextField.font = GeneralFonts.buttonFont
        emailTextField.textColor = GeneralColors.hardButton
        emailTextField.borderStyle = .roundedRect
        return emailTextField
    }()

    private let passwordLabel: UILabel = {
        let passwordLabel = UILabel(frame: .zero)
        passwordLabel.text = "Password"
        passwordLabel.textColor = GeneralColors.text
        passwordLabel.font = GeneralFonts.buttonFont
        passwordLabel.textAlignment = NSTextAlignment.center
        return passwordLabel
    }()

    private let passwordTextField: UITextField = {
        let passwordTextField = UITextField(frame: .zero)
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password...",
                                                                     attributes: [
                                                                    .font : GeneralFonts.buttonFont as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        passwordTextField.font = GeneralFonts.buttonFont
        passwordTextField.textColor = GeneralColors.hardButton
        passwordTextField.borderStyle = .roundedRect
        return passwordTextField
    }()

    private let confirmPasswordLabel: UILabel = {
        let confirmPasswordLabel = UILabel(frame: .zero)
        confirmPasswordLabel.text = "Confirm password"
        confirmPasswordLabel.textColor = GeneralColors.text
        confirmPasswordLabel.font = GeneralFonts.buttonFont
        confirmPasswordLabel.textAlignment = NSTextAlignment.center
        return confirmPasswordLabel
    }()

    private let confirmPasswordTextField: UITextField = {
        let confirmPasswordTextField = UITextField(frame: .zero)
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password...",
                                                                            attributes: [
                                                                    .font : GeneralFonts.buttonFont as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        confirmPasswordTextField.font = GeneralFonts.buttonFont
        confirmPasswordTextField.textColor = GeneralColors.hardButton
        confirmPasswordTextField.borderStyle = .roundedRect
        return confirmPasswordTextField
    }()

    private let submitButton: UIButton = {
        let submitButton = UIButton(frame: .zero)
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        submitButton.titleLabel?.font = GeneralFonts.buttonFont
        return submitButton
    }()

    private let forgotPasswordButton: UIButton = {
        let forgotPasswordButton = UIButton(frame: .zero)
        forgotPasswordButton.setTitle("Forgot password", for: .normal)
        forgotPasswordButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        forgotPasswordButton.titleLabel?.font = GeneralFonts.buttonFont
        return forgotPasswordButton
    }()

    private let loginOrRegisterButton: UIButton = {
        let loginOrRegisterButton = UIButton(frame: .zero)
        loginOrRegisterButton.setTitleColor(GeneralColors.hardButton, for: .normal)
        loginOrRegisterButton.titleLabel?.font = GeneralFonts.buttonFont
        return loginOrRegisterButton
    }()

}

// MARK: View constraints & binding
extension LoginOrRegisterViewController {

    private func installViewBinds() {

        loginOrRegisterButton.addTarget(self, action: #selector(loginOrRegisterButtonPressed), for: .touchUpInside)
    }

    // swiftlint:disable:next function_body_length
    private func installViewConstraints() {
        navigationController?.navigationBar.tintColor = GeneralColors.softButton
        view.backgroundColor = GeneralColors.background
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: GeneralColors.navBarTitle,
                                                                   .font: GeneralFonts.navBarTitle as Any]

        view.addSubview(emailLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordLabel)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordLabel)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(submitButton)
        view.addSubview(forgotPasswordButton)
        view.addSubview(loginOrRegisterButton)

        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        loginOrRegisterButton.translatesAutoresizingMaskIntoConstraints = false

        emailLabel.topAnchor.constraint(equalTo: topLayoutAnchor, constant: 40).isActive = true
        emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true

        emailTextField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor,
                                            constant: LoginOrRegisterViewController.labelToTextFieldDistance).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                 constant: -LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true
        emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                constant: LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true

        passwordLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor,
                                           constant: LoginOrRegisterViewController.fieldDistance).isActive = true
        passwordLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        passwordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true

        passwordTextField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor,
                                               constant: LoginOrRegisterViewController.labelToTextFieldDistance).isActive = true
        passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true
        passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true

        confirmPasswordLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor,
                                                  constant: LoginOrRegisterViewController.fieldDistance).isActive = true
        confirmPasswordLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        confirmPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true

        confirmPasswordTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor,
                                                      constant: LoginOrRegisterViewController.labelToTextFieldDistance).isActive = true
        confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                           constant: -LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true
        confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                          constant: LoginOrRegisterViewController.textFieldToEdgeDistance).isActive = true

        submitButtonTopToPassword = submitButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor,
                                                                      constant: LoginOrRegisterViewController.fieldDistance)
        submitButtonTopToConfirmPassword = submitButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor,
                                                                             constant: LoginOrRegisterViewController.fieldDistance)
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        forgotPasswordButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor,
                                                  constant: LoginOrRegisterViewController.labelToTextFieldDistance).isActive = true
        forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        loginOrRegisterButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor,
                                                   constant: LoginOrRegisterViewController.labelToTextFieldDistance).isActive = true
        loginOrRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    }

    private func showConfirmPasswordField() {
        viewModel.loginOrRegisterState = .register
        confirmPasswordLabel.isHidden = false
        confirmPasswordTextField.isHidden = false

        UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
            self?.confirmPasswordLabel.alpha = 1.0
            self?.confirmPasswordTextField.alpha = 1.0
            self?.submitButtonTopToPassword?.isActive = false
            self?.submitButtonTopToConfirmPassword?.isActive = true
            self?.view.layoutIfNeeded()
        }) { [weak self] _ in // flag not reliable
            guard let self = self else { return }

            self.navigationController?.navigationBar.layer.add(self.fadeTextAnimation, forKey: "fadeText")
            self.navigationItem.title = LoginOrRegisterState.register.rawValue
            UIView.transition(with: self.loginOrRegisterButton,
                              duration: Constants.standardAnimationDuration,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.loginOrRegisterButton.setTitle(LoginOrRegisterState.login.rawValue, for: .normal)
            },
                              completion: nil)
        }
    }

    private func hideConfirmPasswordField(immediately: Bool = false) {
        viewModel.loginOrRegisterState = .login
        navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")

        UIView.animate(withDuration: immediately ? 0.0 : Constants.standardAnimationDuration, animations: { [weak self] in
            self?.confirmPasswordLabel.alpha = 0.0
            self?.confirmPasswordTextField.alpha = 0.0
            self?.submitButtonTopToConfirmPassword?.isActive = false
            self?.submitButtonTopToPassword?.isActive = true
            self?.view.layoutIfNeeded()
        }) { [weak self] _ in // flag not reliable
            guard let self = self else { return }

            self.confirmPasswordLabel.isHidden = true
            self.confirmPasswordTextField.isHidden = true

            self.navigationController?.navigationBar.layer.add(self.fadeTextAnimation, forKey: "fadeText")
            self.navigationItem.title = LoginOrRegisterState.login.rawValue
            UIView.transition(with: self.loginOrRegisterButton,
                              duration: immediately ? 0.0 : Constants.standardAnimationDuration,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.loginOrRegisterButton.setTitle(LoginOrRegisterState.register.rawValue, for: .normal)
            },
                              completion: nil)
        }
    }
}
