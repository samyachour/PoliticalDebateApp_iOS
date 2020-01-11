//
//  Debate.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

typealias PrimaryKey = Int

struct Debate {
    let primaryKey: PrimaryKey
    let title: String
    let shortTitle: String
    let lastUpdated: Date?
    let tags: String
    let allPointsPrimaryKeys: [Int]
    let totalPoints: Int

    let rootPoints: [Point]
    let contextPoints: [Point]
    let sidedPoints: [Point]
}

extension Debate: Decodable {
    enum DebateCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case title
        case shortTitle = "short_title"
        case lastUpdated = "last_updated"
        case rootPoints = "debate_map"
        case allPointsPrimaryKeys = "all_points_primary_keys"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DebateCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        shortTitle = try container.decode(String.self, forKey: .shortTitle)
        title = try container.decode(String.self, forKey: .title)
        lastUpdated = try container.decode(String.self, forKey: .lastUpdated).toDate()
        tags = try container.decode(String.self, forKey: .tags)
        allPointsPrimaryKeys = try container.decode([Int].self, forKey: .allPointsPrimaryKeys)
        totalPoints = allPointsPrimaryKeys.count
        rootPoints = try container.decodeIfPresent([Point].self, forKey: .rootPoints) ?? []

        contextPoints = rootPoints.filter({ point -> Bool in
            switch point.side {
            case .pro,
                 .con,
                 .none:
                return false
            case .context:
                return true
            }
        })
        sidedPoints = rootPoints.filter({ point -> Bool in
            switch point.side {
            case .pro,
                 .con:
                return true
            case .context,
                 .none:
                return false
            }
        })

    }

}

extension Debate: Equatable {
    static func == (lhs: Debate, rhs: Debate) -> Bool {
        return lhs.primaryKey == rhs.primaryKey
    }
}
