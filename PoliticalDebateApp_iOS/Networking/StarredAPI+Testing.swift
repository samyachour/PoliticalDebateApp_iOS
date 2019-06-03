//
//  StarredAPI+Testing.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

extension StarredAPI {

    var sampleData: Data {
        switch self {
        case .starDebate:
            return StubAccess.stubbedResponse("Empty")
        case .loadAllStarred:
            return StubAccess.stubbedResponse("Starred")
        }
    }
}
