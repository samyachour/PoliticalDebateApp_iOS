//
//  API.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum AuthAPI {
    case tokenRefresh(refreshToken: String)
    case tokenObtain(email: String, password: String)
    case registerUser(email: String, password: String)
    case changePassword(oldPassword: String, newPassword: String)
    case requestPasswordReset(email: String, forceSend: Bool?)
    case changeEmail(newEmail: String)
    case getCurrentEmail
    case requestVerificationLink
    case delete
}

extension AuthAPI: CustomTargetType {

    enum Constants {
        static let accessTokenKey = "access"
        static let refreshTokenKey = "refresh"
        static let emailKey = "email"
        static let usernameKey = "username"
        static let passwordKey = "password"
        static let oldPasswordKey = "old_password"
        static let newPasswordKey = "new_password"
        static let forceSendKey = "force_send"
        static let newEmailKey = "new_email"
    }

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .tokenRefresh:
            return "v1/auth/token/refresh/"
        case .tokenObtain:
            return "v1/auth/token/obtain/"
        case .registerUser:
            return "v1/auth/register/"
        case .changePassword:
            return "v1/auth/change-password/"
        case .requestPasswordReset:
            return "v1/auth/request-password-reset/"
        case .changeEmail:
            return "v1/auth/change-email/"
        case .getCurrentEmail:
            return "v1/auth/get-current-email/"
        case .requestVerificationLink:
            return "v1/auth/request-verification-link/"
        case .delete:
            return "v1/auth/delete/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .tokenRefresh,
             .tokenObtain,
             .registerUser,
             .requestPasswordReset,
             .delete:
            return .post
        case .changeEmail,
             .changePassword,
             .requestVerificationLink:
            return .put
        case .getCurrentEmail:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .tokenRefresh(let refreshToken):
            return .requestParameters(parameters: [Constants.refreshTokenKey : refreshToken], encoding: JSONEncoding.default)
        case .tokenObtain(let email, let password):
            // SimpleJWT requires 'username' parameter for obtaining tokens
            return .requestParameters(parameters: [Constants.usernameKey: email.lowercased(), // all backend emails are saved as lowercase, just being safe
                                                   Constants.passwordKey: password],
                                      encoding: JSONEncoding.default)
        case .registerUser(let email, let password):
            return .requestParameters(parameters: [Constants.emailKey: email.lowercased(),
                                                   Constants.passwordKey: password],
                                      encoding: JSONEncoding.default)
        case .changePassword(let oldPassword, let newPassword):
            return .requestParameters(parameters: [Constants.oldPasswordKey: oldPassword,
                                                   Constants.newPasswordKey: newPassword],
                                      encoding: JSONEncoding.default)
        case .requestPasswordReset(let email, let forceSend):
            var params: [String: Any] = [Constants.emailKey: email.lowercased()]
            params[Constants.forceSendKey] = forceSend
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .changeEmail(let newEmail):
            return .requestParameters(parameters: [Constants.newEmailKey: newEmail.lowercased()],
                                      encoding: JSONEncoding.default)
        case .delete,
             .getCurrentEmail,
             .requestVerificationLink:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validSuccessCode: Int {
        switch self {
        case .tokenRefresh,
             .tokenObtain,
             .requestPasswordReset,
             .delete,
             .changeEmail,
             .changePassword,
             .getCurrentEmail,
             .requestVerificationLink:
            return 200
        case .registerUser:
            return 201
        }
    }

}

extension AuthAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .tokenRefresh,
             .tokenObtain,
             .registerUser,
             .requestPasswordReset:
            return .none
        case .changePassword,
             .changeEmail,
             .delete,
             .getCurrentEmail,
             .requestVerificationLink:
            return .bearer
        }
    }
}

// For unit testing
extension AuthAPI {

    var sampleData: Data {
        switch self {
        case .tokenRefresh:
            return StubAccess.stubbedResponse("TokenRefresh")
        case .tokenObtain:
            return StubAccess.stubbedResponse("TokenObtain")
        case .getCurrentEmail:
            return StubAccess.stubbedResponse("GetCurrentEmail")
        case .registerUser,
             .changePassword,
             .requestPasswordReset,
             .changeEmail,
             .delete,
             .requestVerificationLink:
            return StubAccess.stubbedResponse("Empty")
        }
    }
}
