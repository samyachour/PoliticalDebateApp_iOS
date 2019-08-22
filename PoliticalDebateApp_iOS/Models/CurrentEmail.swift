//
//  CurrentEmail.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

struct CurrentEmail {
    let email: String
    let isVerified: Bool
}

extension CurrentEmail: Decodable {
    enum TokenPairCodingKeys: String, CodingKey {
        case email = "current_email"
        case isVerified = "is_verified"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TokenPairCodingKeys.self)

        email = try container.decode(String.self, forKey: .email)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
    }
}
