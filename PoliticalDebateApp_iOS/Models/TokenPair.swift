//
//  TokenPair.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 5/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

public struct TokenPair {
    let accessTokenString: String
    let refreshTokenString: String?
}

extension TokenPair: Decodable {
    enum TokenPairCodingKeys: String, CodingKey {
        case accessTokenString = "access"
        case refreshTokenString = "refresh"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TokenPairCodingKeys.self)

        accessTokenString = try container.decode(String.self, forKey: .accessTokenString)
        // On refresh requests we only get the access token back
        refreshTokenString = try container.decodeIfPresent(String.self, forKey: .refreshTokenString)
    }
}
