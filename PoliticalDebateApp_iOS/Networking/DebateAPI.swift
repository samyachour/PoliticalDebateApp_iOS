//
//  API.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum DebateAPI {
    case debate(primaryKey: Int)
    case debates
}

extension DebateAPI: TargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .debate:
            return "debate/"
        case .debates:
            return "debates/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .debate,
        .debates:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .debate(let primaryKey):
            return .requestParameters(parameters: ["pk" : primaryKey], encoding: PlainDjangoEncoding())
        case .debates:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
    }

}

extension DebateAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .debate,
             .debates:
            return .none
        }
    }
}
