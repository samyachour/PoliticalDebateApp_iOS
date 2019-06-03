//
//  ProgressAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum ProgressAPI {
    case saveProgress(debatePrimaryKey: Int, debatePoint: String)
    case loadProgress(debatePrimaryKey: Int)
    case loadAllProgress
}

public enum ProgressConstants {
    static let debatePointKey = "debate_point"
}

extension ProgressAPI: TargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .saveProgress,
             .loadProgress,
             .loadAllProgress:
            return "progress/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .saveProgress:
            return .post
        case .loadProgress,
             .loadAllProgress:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .saveProgress(let debatePrimaryKey, let debatePoint):
            return .requestParameters(parameters: [DebateConstants.primaryKey: debatePrimaryKey,
                                                   ProgressConstants.debatePointKey: debatePoint],
                                      encoding: JSONEncoding.default)
        case .loadProgress(let debatePrimaryKey):
            return .requestParameters(parameters: [DebateConstants.primaryKey: debatePrimaryKey], encoding: PlainDjangoEncoding())
        case .loadAllProgress:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        return nil
    }

}

extension ProgressAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .saveProgress,
             .loadProgress,
             .loadAllProgress:
            return .bearer
        }
    }
}
