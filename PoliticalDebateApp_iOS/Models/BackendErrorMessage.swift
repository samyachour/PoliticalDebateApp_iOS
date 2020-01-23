//
//  BackendErrorMessage.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/1/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

/// Data the backend sends us in custom errors
struct BackendErrorMessage {
    let messageString: String

    // Key words to discern between multiple custom errors from the same endpoint
    static let unverifiedEmailKeyword = "unverified"
}

extension BackendErrorMessage: Decodable {
    enum BackendErrorMessageCodingKeys: String, CodingKey {
        case messageString = "message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BackendErrorMessageCodingKeys.self)

        messageString = try container.decode(String.self, forKey: .messageString)
    }
}
