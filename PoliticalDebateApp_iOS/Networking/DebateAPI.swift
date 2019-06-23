//
//  DebateAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum DebateAPI {
    case debate(primaryKey: PrimaryKey)
    case debateSearch(searchString: String)
}

public enum DebateConstants {
    static let primaryKey = "pk"
    static let searchStringKey = "search_string"
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
        case .debateSearch:
            return "debate/search/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .debate,
        .debateSearch:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .debate(let primaryKey):
            return .requestParameters(parameters: [DebateConstants.primaryKey : primaryKey], encoding: PlainDjangoEncoding())
        case .debateSearch(let searchString):
            return .requestParameters(parameters: [DebateConstants.searchStringKey : searchString], encoding: PlainDjangoEncoding())
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
             .debateSearch:
            return .none
        }
    }
}
