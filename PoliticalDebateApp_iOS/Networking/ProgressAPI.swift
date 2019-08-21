//
//  ProgressAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

enum ProgressAPI {
    case saveProgress(debatePrimaryKey: PrimaryKey, pointPrimaryKey: PrimaryKey)
    case loadProgress(debatePrimaryKey: PrimaryKey)
    case loadAllProgress
    case saveBatchProgress(batchProgress: [Progress])
}

enum ProgressConstants {
    static let debatePrimaryKey = "debate_pk"
    static let pointPrimaryKey = "point_pk"
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
        case .saveProgress(let debatePrimaryKey, let pointPrimaryKey):
            return .requestParameters(parameters: [ProgressConstants.debatePrimaryKey: debatePrimaryKey,
                                                   ProgressConstants.pointPrimaryKey: pointPrimaryKey],
                                      encoding: JSONEncoding.default)
        case .loadProgress(let debatePrimaryKey):
            return .requestParameters(parameters: [DebateConstants.primaryKeyKey: debatePrimaryKey], encoding: PlainDjangoEncoding())
        case .loadAllProgress:
            return .requestPlain
        case .saveBatchProgress(let batchProgress):
            return .requestParameters(parameters: [ProgressConstants.allDebatePointsKeys : batchProgress], encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validationType: ValidationType {
        switch self {
        case .saveProgress,
             .saveBatchProgress:
            return .customCodes([201])
        case .loadProgress,
             .loadAllProgress:
            return .customCodes([200])
        }
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

// For unit testing
extension ProgressAPI {

    var sampleData: Data {
        switch self {
        case .saveProgress,
             .saveBatchProgress:
            return StubAccess.stubbedResponse("Empty")
        case .loadProgress:
            return StubAccess.stubbedResponse("ProgressSingle")
        case .loadAllProgress:
            return StubAccess.stubbedResponse("ProgressAll")
        }
    }
}
