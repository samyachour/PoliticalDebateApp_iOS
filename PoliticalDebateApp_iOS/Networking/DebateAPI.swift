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
    case debateFilter(searchString: String?, filter: SortByOption?)
}

extension DebateAPI: CustomTargetType {

    enum Constants {
        static let primaryKeyKey = "pk"
        static let searchStringKey = "search_string"
        static let filterKey = "filter"
        static let starredPrimaryKeysKey = "all_starred"
        static let progressPrimaryKeysKey = "all_progress"
        static let lastUpdatedFilterValue = "last_updated"
        static let starredFilterValue = "starred"
        static let progressFilterValue = "progress"
        static let noProgressFilterValue = "no_progress"
        static let randomFilterValue = "random"
    }

    var baseURL: URL {
        guard let url = URL(string: GeneralConstants.appBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }

    var path: String {
        switch self {
        case .debate:
            return "v1/debate/"
        case .debateFilter:
            return "v1/debate/filter/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .debate:
            return .get
        case .debateFilter:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .debate(let primaryKey):
            return .requestParameters(parameters: [Constants.primaryKeyKey : primaryKey], encoding: PlainDjangoEncoding())
        case .debateFilter(let searchString, let filter):
            var params = [String: Any]()
            if let searchString = searchString,
                !searchString.isEmpty {
                params[Constants.searchStringKey] = searchString
            }
            if let filter = filter {
                params[Constants.filterKey] = filter.backendFilterName
                if let filterArrayName = filter.arrayFilterName,
                    let filterArray = filter.primaryKeysArray {
                    params[filterArrayName] = filterArray
                }
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validSuccessCode: Int {
        switch self {
        case .debate,
             .debateFilter:
            return 200
        }
    }

}

extension SortByOption {

    var backendFilterName: String {
        switch self {
        case .sortBy, // backend sorting defaults to last updated
             .lastUpdated:
            return DebateAPI.Constants.lastUpdatedFilterValue
        case .starred:
            return DebateAPI.Constants.starredFilterValue
        case .progressAscending,
             .progressDescending:
            return DebateAPI.Constants.progressFilterValue
        case .noProgress:
            return DebateAPI.Constants.noProgressFilterValue
        case .random:
            return DebateAPI.Constants.randomFilterValue
        }
    }

    var arrayFilterName: String? {
        switch self {
        case .starred:
            return DebateAPI.Constants.starredPrimaryKeysKey
        case .progressAscending,
             .progressDescending,
             .noProgress:
            return DebateAPI.Constants.progressPrimaryKeysKey
        default:
            return nil
        }
    }

    var primaryKeysArray: [PrimaryKey]? {
        switch self {
        case .starred:
            return UserDataManager.shared.starredArray
        case .progressAscending,
             .progressDescending,
             .noProgress:
            return UserDataManager.shared.allProgressArray
                .filter { !$0.seenPoints.isEmpty }
                .map { $0.debatePrimaryKey }
        default:
            return nil
        }
    }
}

extension DebateAPI: AccessTokenAuthorizable {

    var authorizationType: AuthorizationType {
        switch self {
        case .debate,
             .debateFilter:
            return .none
        }
    }
}

// For unit testing
extension DebateAPI {

    var sampleData: Data {
        switch self {
        case .debate:
            return StubAccess.stubbedResponse("DebateSingle")
        case .debateFilter:
            return StubAccess.stubbedResponse("DebateFilter")
        }
    }
}
