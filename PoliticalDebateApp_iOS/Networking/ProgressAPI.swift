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
    case saveBatchProgress(batchProgress: [Progress])
}

public enum ProgressConstants {
    static let debatePointKey = "debate_point"
    static let allDebatePointsKeys = "all_debate_points"
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
        case .saveBatchProgress:
            return "progress/batch/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .saveProgress,
             .saveBatchProgress:
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
        case .saveBatchProgress(let batchProgress):
            return .requestParameters(parameters: [ProgressConstants.allDebatePointsKeys : batchProgress], encoding: JSONEncoding.default)
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
             .loadAllProgress,
             .saveBatchProgress:
            return .bearer
        }
    }
}
