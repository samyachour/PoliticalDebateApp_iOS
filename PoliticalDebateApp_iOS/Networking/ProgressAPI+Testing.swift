//
//  ProgressAPI+Testing.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

extension ProgressAPI {

    var sampleData: Data {
        switch self {
        case .saveProgress,
             .saveBatchProgress:
            return StubAccess.stubbedResponse("Empty")
        case .loadProgress:
            return StubAccess.stubbedResponse("Progress")
        case .loadAllProgress:
            return StubAccess.stubbedResponse("ProgressAll")
        }
    }
}
