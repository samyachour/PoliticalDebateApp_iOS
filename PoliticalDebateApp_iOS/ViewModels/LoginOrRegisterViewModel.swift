//
//  LoginOrRegisterViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

enum LoginOrRegisterState: String { // raw value for labels
    case login = "Login"
    case register = "Register"

    var otherState: LoginOrRegisterState {
        switch self {
        case .login:
            return .register
        case .register:
            return .login
        }
    }
}

class LoginOrRegisterViewModel {

    // MARK: - Dependencies
    private let authNetworkService = NetworkService<AuthAPI>()

    // MARK: - Observables

    var loginOrRegisterStateRelay = BehaviorRelay<(state: LoginOrRegisterState, animated: Bool)>(value: (.login, false))

    // We need to trigger this from 2 places, the button and an alert action
    let forgotPasswordRelay = PublishRelay<(email: String, force: Bool)>()
    lazy var forgotPasswordObservable: Observable<Single<Response>> = {
        forgotPasswordRelay.map { [weak self] emailText, force -> Single<Response> in
            guard let self = self else {
                return .error(GeneralError.basic)
            }
            return self.authNetworkService.makeRequest(with: .requestPasswordReset(email: emailText,
                                                                                   forceSend: force))
        }
    }()
}

enum LoginOrRegisterErrors: Error {
    case emptyEmailField
    case emptyPasswordField
    case emptyConfirmPasswordField

    var localizedDescription: String {
        switch self {
        case .emptyEmailField:
            return "Please fill in your email."
        case .emptyPasswordField:
            return "Please fill in your password."
        case .emptyConfirmPasswordField:
            return "Please confirm your password."
        }
    }
}
