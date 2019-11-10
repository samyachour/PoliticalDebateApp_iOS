//
//  Progress.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

struct Progress {
    let debatePrimaryKey: PrimaryKey
    let seenPoints: [PrimaryKey]
}

extension Progress: Codable {
    private enum CodingKeys: String, CodingKey {
        case debatePrimaryKey = "debate"
        case seenPoints = "seen_points"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        debatePrimaryKey = try container.decode(PrimaryKey.self, forKey: .debatePrimaryKey)
        seenPoints = try container.decode([PrimaryKey].self, forKey: .seenPoints)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(debatePrimaryKey, forKey: .debatePrimaryKey)
        try container.encode(seenPoints, forKey: .seenPoints)
    }
}

extension Progress: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(debatePrimaryKey)
    }
}

// Initializing from CoreData model
extension Progress {
    init?(from progress: LocalProgress) {
        guard let debatePrimaryKey32 = progress.debate?.primaryKey,
        let seenPoints = progress.seenPoints?.allObjects as? [LocalPoint] else {
                return nil
        }
        self.init(debatePrimaryKey: Int(debatePrimaryKey32),
                  seenPoints: seenPoints.map { Int($0.primaryKey) })
    }
}

struct BatchProgress {
    let allDebatePoints: [Progress]
}

extension BatchProgress: Encodable {
    private enum CodingKeys: String, CodingKey {
        case allDebatePoints = "all_debate_points"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(allDebatePoints, forKey: .allDebatePoints)
    }
}
