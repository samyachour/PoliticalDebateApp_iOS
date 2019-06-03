//
//  Progress.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

struct Progress {
    let debatePrimaryKey: Int
    let completed: Bool
    let seenPoints: [String]
}

extension Progress: Decodable {
    enum ProgressCodingKeys: String, CodingKey {
        case debatePrimaryKey = "debate"
        case completed
        case seenPoints = "seen_points"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ProgressCodingKeys.self)

        debatePrimaryKey = try container.decode(Int.self, forKey: .debatePrimaryKey)
        completed = try container.decode(Bool.self, forKey: .completed)
        seenPoints = try container.decode([String].self, forKey: .seenPoints)
    }
}
