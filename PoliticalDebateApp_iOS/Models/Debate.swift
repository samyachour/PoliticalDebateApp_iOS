//
//  User.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import SwiftyJSON

struct Debate {
    let primaryKey: Int
    let title: String
    let lastUpdated: Date?
    let totalPoints: Int
    let debateMap: JSON?
}

extension Debate: Decodable {
    enum DebateCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case title
        case lastUpdated = "last_updated"
        case totalPoints = "total_points"
        case debateMap = "debate_map"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DebateCodingKeys.self)

        primaryKey = try container.decode(Int.self, forKey: .primaryKey)
        title = try container.decode(String.self, forKey: .title)
        lastUpdated = try container.decode(String.self, forKey: .lastUpdated).toDate()
        totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        // We don't get the map with the search call
        debateMap = try container.decodeIfPresent(JSON.self, forKey: .debateMap)
    }
}
