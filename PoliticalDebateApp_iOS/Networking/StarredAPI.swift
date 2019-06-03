//
//  StarredAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum StarredAPI {
    case starDebate(debatePrimaryKey: Int)
    case loadAllStarred
}

public enum StarredConstants {
    static let starredListKey = "starred_list"
}

extension StarredAPI: TargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .starDebate,
             .loadAllStarred:
            return "starred-list/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .starDebate:
            return .post
        case .loadAllStarred:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .starDebate(let debatePrimaryKey):
            return .requestParameters(parameters: [DebateConstants.primaryKey : debatePrimaryKey], encoding: JSONEncoding.default)
        case .loadAllStarred:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
    }

}

extension StarredAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .starDebate,
             .loadAllStarred:
            return .bearer
        }
    }
}
