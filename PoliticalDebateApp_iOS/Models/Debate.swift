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
    let debateMap: [Point]
    var contextPoints: [Point] {
        return debateMap.filter({ (point) -> Bool in
            switch point.side {
            case .pro,
                 .con:
                return false
            case .context:
                return true
            case .none:
                return false
            }
        })
    }
    var sidedPoints: [Point] {
        return debateMap.filter({ (point) -> Bool in
            switch point.side {
            case .pro,
                 .con:
                return true
            case .context:
                return false
            case .none:
                return false
            }
        })
    }
    // Recursively generated array of all point objects
    private var allPoints: [Point] {
        return getAllPoints()
    }
    var allPointsPrimaryKeys: [PrimaryKey] {
        return allPoints.map({ $0.primaryKey })
    }
    var totalPoints: Int {
        return allPoints.count
    }

    private func getAllPoints(_ point: Point? = nil) -> [Point] {
        guard let point = point else {
            return debateMap.reduce([]) { (allPoints, point) -> [Point] in
                return allPoints + getAllPoints(point).filter({ !allPoints.contains($0) }) // avoid duplicates
            }
        }

        guard let rebuttals = point.rebuttals,
            !rebuttals.isEmpty else {
                return [point]
        }

        return rebuttals.reduce([point]) { (allPoints, point) -> [Point] in
            return allPoints + getAllPoints(point).filter({ !allPoints.contains($0) }) // avoid duplicates
        }
    }
}

extension Debate: Decodable {
    enum DebateCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case title
        case shortTitle = "short_title"
        case lastUpdated = "last_updated"
        case debateMap = "debate_map"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DebateCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        shortTitle = try container.decode(String.self, forKey: .shortTitle)
        title = try container.decode(String.self, forKey: .title)
        lastUpdated = try container.decode(String.self, forKey: .lastUpdated).toDate()
        debateMap = try container.decode([Point].self, forKey: .debateMap)
    }
}

extension Debate: Equatable {
    static func == (lhs: Debate, rhs: Debate) -> Bool {
        return lhs.primaryKey == rhs.primaryKey
    }
}
