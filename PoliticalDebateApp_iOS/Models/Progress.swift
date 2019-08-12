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
    let completedPercentage: Int
    var seenPoints: [PrimaryKey]?

    init(debatePrimaryKey: PrimaryKey, completedPercentage: Int, seenPoints: [PrimaryKey]? = nil) {
        self.debatePrimaryKey = debatePrimaryKey
        self.completedPercentage = completedPercentage
        self.seenPoints = seenPoints
    }
}

extension Progress: Codable {
    private enum CodingKeys: String, CodingKey {
        case debatePrimaryKey = "debate"
        case completedPercentage = "completed_percentage"
        case seenPoints = "seen_points"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        debatePrimaryKey = try container.decode(PrimaryKey.self, forKey: .debatePrimaryKey)
        completedPercentage = try container.decode(Int.self, forKey: .completedPercentage)
        // We don't get seen points w/ the load all call
        seenPoints = try container.decodeIfPresent([PrimaryKey].self, forKey: .seenPoints)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(debatePrimaryKey, forKey: .debatePrimaryKey)
        try container.encode(seenPoints, forKey: .seenPoints)
    }
}

extension Progress: Comparable {
    static func < (lhs: Progress, rhs: Progress) -> Bool {
        return lhs.completedPercentage < rhs.completedPercentage
    }
}

// Initializing from CoreData model
extension Progress {
    init?(from progress: LocalProgress, withSeenPoints: Bool = false) {
        guard let debatePrimaryKey32 = progress.debate?.primaryKey,
        let seenPoints = progress.seenPoints?.allObjects as? [LocalPoint] else {
                return nil
        }
        if withSeenPoints {
            self.init(debatePrimaryKey: Int(debatePrimaryKey32),
                      completedPercentage: Int(progress.completedPercentage),
                      seenPoints: seenPoints.map { Int($0.primaryKey) })
        } else {
            self.init(debatePrimaryKey: Int(debatePrimaryKey32),
                      completedPercentage: Int(progress.completedPercentage))
        }
    }
}
