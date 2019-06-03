//
//  DebateAPI+Testing.swift
//  PoliticalDebateApp_iOSTests
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

extension DebateAPI {

    var sampleData: Data {
        switch self {
        case .debate:
            return StubAccess.stubbedResponse("Debate")
        case .debateSearch:
            return StubAccess.stubbedResponse("DebateSearch")
        }
    }
}
