//
//  Progress.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

struct Progress {
    let debatePrimaryKey: Int
    let completedPercentage: Int
    let seenPoints: [String]?
}

extension Progress: Codable {
    private enum CodingKeys: String, CodingKey {
        case debatePrimaryKey = "debate"
        case completedPercentage = "completed_percentage"
        case seenPoints = "seen_points"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        debatePrimaryKey = try container.decode(Int.self, forKey: .debatePrimaryKey)
        completedPercentage = try container.decode(Int.self, forKey: .completedPercentage)
        // We don't get seen points w/ the load all call
        seenPoints = try container.decodeIfPresent([String].self, forKey: .seenPoints)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(debatePrimaryKey, forKey: .debatePrimaryKey)
        try container.encode(seenPoints, forKey: .seenPoints)
    }
}
