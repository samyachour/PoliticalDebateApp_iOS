//
//  API+Testing.swift
//  PoliticalDebateApp_iOSTests
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

extension AuthAPI {

    var sampleData: Data {
        switch self {
        case .tokenRefresh:
            return StubAccess.stubbedResponse("TokenRefresh")
        case .tokenObtain:
            return StubAccess.stubbedResponse("TokenObtain")
        }
    }
}
