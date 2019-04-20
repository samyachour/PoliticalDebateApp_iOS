//
//  API+Testing.swift
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
            return stubbedResponse("Debate")
        case .debates:
            return stubbedResponse("Debates")
        }
    }
}

private func stubbedResponse(_ filename: String) -> Data {
    // These files are hardcoded so we know they exist
    // swiftlint:disable force_try
    let path = Bundle.main.path(forResource: filename, ofType: "json")!
    return try! Data(contentsOf: URL(fileURLWithPath: path))
}
