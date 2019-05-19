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
    case tokenObtain(email: String, username: String, password: String)
}

public enum AuthConstants {
    static let tokenRefreshKey = "refresh"
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
        }
    }

    var method: Moya.Method {
        switch self {
        case .tokenRefresh,
             .tokenObtain:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .tokenRefresh(let refreshToken):
            return .requestParameters(parameters: ["refresh" : refreshToken], encoding: JSONEncoding.default)
        case .tokenObtain(let email, let username, let password):
            return .requestParameters(parameters: ["email": email,
                                                   "username": username,
                                                   "password": password],
                                      encoding: JSONEncoding.default)
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
             .tokenObtain:
            return .none
        }
    }
}
