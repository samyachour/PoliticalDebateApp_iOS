//
//  AccessToken.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 5/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

public struct AccessToken {
    let accessTokenString: String
}

extension AccessToken: Decodable {
    enum AccessTokenCodingKeys: String, CodingKey {
        case accessTokenString = "access"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AccessTokenCodingKeys.self)

        accessTokenString = try container.decode(String.self, forKey: .accessTokenString)
    }
}
