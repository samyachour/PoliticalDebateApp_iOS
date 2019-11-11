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

    let rootPoints: [Point]
    let contextPoints: [Point]
    let sidedPoints: [Point]

    let allPoints: [Point]
    let allPointsPrimaryKeys: [PrimaryKey]
    let totalPoints: Int

    private static func getAllPoints(from rootPoints: [Point] = [],
                                     with point: Point? = nil) -> [Point] {
        guard let point = point else {
            return rootPoints.reduce([]) { (allPoints, point) -> [Point] in
                return allPoints + getAllPoints(with: point).filter({ !allPoints.contains($0) }) // avoid duplicates
            }
        }

        guard let rebuttals = point.rebuttals,
            !rebuttals.isEmpty else {
                return [point]
        }

        return rebuttals.reduce([point]) { (allPoints, point) -> [Point] in
            return allPoints + getAllPoints(with: point).filter({ !allPoints.contains($0) }) // avoid duplicates
        }
    }
}

extension Debate: Decodable {
    enum DebateCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case title
        case shortTitle = "short_title"
        case lastUpdated = "last_updated"
        case rootPoints = "debate_map"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DebateCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        shortTitle = try container.decode(String.self, forKey: .shortTitle)
        title = try container.decode(String.self, forKey: .title)
        lastUpdated = try container.decode(String.self, forKey: .lastUpdated).toDate()
        rootPoints = try container.decode([Point].self, forKey: .rootPoints)

        allPoints = Self.getAllPoints(from: rootPoints)
        allPointsPrimaryKeys = allPoints.map({ $0.primaryKey })
        totalPoints = allPointsPrimaryKeys.count

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
