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
}

class LoginOrRegisterViewModel {

    var loginOrRegisterState = LoginOrRegisterState.login
    private let authNetworkService = NetworkService<AuthAPI>()

    // MARK: - Action handlers

    func getForgotPasswordRequestObservable(_ forgotPasswordRelay: PublishRelay<(String, Bool)>) -> Observable<Single<Response>> {
        return forgotPasswordRelay.map { [weak self] emailText, force -> Single<Response> in
            guard let self = self else {
                return .error(GeneralError.basic)
            }
             return self.authNetworkService.makeRequest(with: .requestPasswordReset(email: emailText,
                                                                                    forceSend: force))
        }
    }
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
