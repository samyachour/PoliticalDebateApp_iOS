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
    case login = "Log in"
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

    private lazy var authNetworkService = NetworkService<AuthAPI>()

    // MARK: - Observables

    var loginOrRegisterStateRelay = BehaviorRelay<(state: LoginOrRegisterState, animated: Bool)>(value: (.login, false))

    // MARK: - API Requests

    func forgotPassword(email: String, forceSend: Bool) -> Single<Response> {
        return authNetworkService.makeRequest(with: .requestPasswordReset(email: email, forceSend: forceSend))
    }

    func login(with email: String, password: String) -> Single<Void> {
        return SessionManager.shared.login(email: email, password: password) // need to pass through SessionManager so it can grab tokens
    }

    func register(email: String, password: String) -> Single<Response> {
        return authNetworkService.makeRequest(with: .registerUser(email: email, password: password))
    }
}
