//
//  Starred.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

struct Starred {
    var starredList: [PrimaryKey]
    var unstarredList: [PrimaryKey]?

    init(starredList: [PrimaryKey], unstarredList: [PrimaryKey]? = nil) {
        self.starredList = starredList
        self.unstarredList = unstarredList
    }
}

extension Starred: Codable {
    private enum CodingKeys: String, CodingKey {
        case starredList = "starred_list"
        case unstarredList = "unstarred_list"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        starredList = try container.decode([PrimaryKey].self, forKey: .starredList)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(starredList, forKey: .starredList)
        try container.encode(unstarredList, forKey: .unstarredList)
    }
}

// Initializing from CoreData model
extension Starred {
    init?(from starred: LocalStarred) {
        guard let starredList = starred.starredList?.allObjects as? [LocalDebate] else {
            return nil
        }

        self.init(starredList: starredList.map { Int($0.primaryKey) })
    }
}
