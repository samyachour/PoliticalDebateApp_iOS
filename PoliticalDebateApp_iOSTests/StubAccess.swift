//
//  StubAccess.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

class StubAccess {
    static func stubbedResponse(_ filename: String) -> Data {
        // These files are hardcoded so we know they exist
        // swiftlint:disable force_try
        let path = Bundle.main.url(forResource: filename, withExtension: "json")!
        return try! Data(contentsOf: path)
    }
}
