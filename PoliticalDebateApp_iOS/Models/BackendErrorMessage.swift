//
//  BackendErrorMessage.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/1/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

// Data the backend sends us in custom errors
struct BackendErrorMessage {
    let messageString: String

    static let customErrorCode = 400

    // Key words to discern between multiple custom errors from the same endpoint
    static let invalidEmailKeyword = "invalid"
    static let unverifiedEmailKeyword = "verify"
    static let alreadyUsingEmailKeyword = "already"
}

extension BackendErrorMessage: Decodable {
    enum BackendErrorMessageCodingKeys: String, CodingKey {
        case messageString = "message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BackendErrorMessageCodingKeys.self)

        messageString = try container.decode(String.self, forKey: .messageString).lowercased()
    }
}
