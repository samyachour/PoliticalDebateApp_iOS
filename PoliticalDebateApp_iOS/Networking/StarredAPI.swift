//
//  StarredAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum StarredAPI {
    case starOrUnstarDebates(starred: [PrimaryKey], unstarred: [PrimaryKey])
    case loadAllStarred
}

enum StarredConstants {
    static let starredListKey = "starred_list"
    static let unstarredListKey = "unstarred_list"
}

extension StarredAPI: TargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .starOrUnstarDebates,
             .loadAllStarred:
            return "starred/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .starOrUnstarDebates:
            return .post
        case .loadAllStarred:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .starOrUnstarDebates(let starred, let unstarred):
            return .requestParameters(parameters: [StarredConstants.starredListKey : starred,
                                                   StarredConstants.unstarredListKey : unstarred],
                                      encoding: JSONEncoding.default)
        case .loadAllStarred:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validationType: ValidationType {
        switch self {
        case .starOrUnstarDebates:
            return .customCodes([201])
        case .loadAllStarred:
            return .customCodes([200])
        }
    }

}

extension StarredAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .starOrUnstarDebates,
             .loadAllStarred:
            return .bearer
        }
    }
}

// For unit testing
extension StarredAPI {

    var sampleData: Data {
        switch self {
        case .starOrUnstarDebates:
            return StubAccess.stubbedResponse("Empty")
        case .loadAllStarred:
            return StubAccess.stubbedResponse("Starred")
        }
    }
}
