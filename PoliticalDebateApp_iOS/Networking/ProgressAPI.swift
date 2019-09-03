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
    case loadAllProgress
    case saveBatchProgress(batchProgress: BatchProgress)
}

enum ProgressConstants {
    static let debatePrimaryKey = "debate_pk"
    static let pointPrimaryKey = "point_pk"
}

extension ProgressAPI: CustomTargetType {

    var baseURL: URL {
        guard let url = URL(string: appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .saveProgress,
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
            return .put
        case .loadAllProgress:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .saveProgress(let debatePrimaryKey, let pointPrimaryKey):
            return .requestParameters(parameters: [ProgressConstants.debatePrimaryKey: debatePrimaryKey,
                                                   ProgressConstants.pointPrimaryKey: pointPrimaryKey],
                                      encoding: JSONEncoding.default)
        case .loadAllProgress:
            return .requestPlain
        case .saveBatchProgress(let batchProgress):
            return .requestJSONEncodable(batchProgress)
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validSuccessCode: Int {
        switch self {
        case .saveProgress,
             .saveBatchProgress:
            return 201
        case .loadAllProgress:
            return 200
        }
    }

}

extension ProgressAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .saveProgress,
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
        case .loadAllProgress:
            return StubAccess.stubbedResponse("ProgressAll")
        }
    }
}
