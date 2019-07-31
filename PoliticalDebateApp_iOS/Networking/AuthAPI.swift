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
    case delete
}

enum AuthConstants {
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

extension AuthAPI: TargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url.appendingPathComponent("auth/")
    }

    var path: String {
        switch self {
        case .tokenRefresh:
            return "token/refresh/"
        case .tokenObtain:
            return "token/obtain/"
        case .registerUser:
            return "register/"
        case .changePassword:
            return "change-password/"
        case .requestPasswordReset:
            return "request-password-reset/"
        case .changeEmail:
            return "change-email/"
        case .delete:
            return "delete/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .tokenRefresh,
             .tokenObtain,
             .registerUser,
             .changePassword,
             .requestPasswordReset,
             .changeEmail,
             .delete:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .tokenRefresh(let refreshToken):
            return .requestParameters(parameters: [AuthConstants.refreshTokenKey : refreshToken], encoding: JSONEncoding.default)
        case .tokenObtain(let email, let password):
            // SimpleJWT requires 'username' parameter for obtaining tokens
            return .requestParameters(parameters: [AuthConstants.usernameKey: email.lowercased(), // all backend emails are saved as lowercase, just being safe
                                                   AuthConstants.passwordKey: password],
                                      encoding: JSONEncoding.default)
        case .registerUser(let email, let password):
            return .requestParameters(parameters: [AuthConstants.emailKey: email.lowercased(),
                                                   AuthConstants.passwordKey: password],
                                      encoding: JSONEncoding.default)
        case .changePassword(let oldPassword, let newPassword):
            return .requestParameters(parameters: [AuthConstants.oldPasswordKey: oldPassword,
                                                   AuthConstants.newPasswordKey: newPassword],
                                      encoding: JSONEncoding.default)
        case .requestPasswordReset(let email, let forceSend):
            var params: [String: Any] = [AuthConstants.emailKey: email.lowercased()]
            params[AuthConstants.forceSendKey] = forceSend
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .changeEmail(let newEmail):
            return .requestParameters(parameters: [AuthConstants.newEmailKey: newEmail.lowercased()],
                                      encoding: JSONEncoding.default)
        case .delete:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
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
             .delete:
            return .bearer
        }
    }
}
