//
//  TokenPair.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 5/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

public struct TokenPair {
    let accessTokenString: String
    let refreshTokenString: String
}

extension TokenPair: Decodable {
    enum TokenPairCodingKeys: String, CodingKey {
        case accessTokenString = "access"
        case refreshTokenString = "refresh"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TokenPairCodingKeys.self)

        accessTokenString = try container.decode(String.self, forKey: .accessTokenString)
        refreshTokenString = try container.decode(String.self, forKey: .refreshTokenString)
    }
}
