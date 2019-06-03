//
//  Starred.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

struct Starred {
    let starredList: [Int]
}

extension Starred: Decodable {
    enum StarredCodingKeys: String, CodingKey {
        case starredList = "starred_list"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StarredCodingKeys.self)

        starredList = try container.decode([Int].self, forKey: .starredList)
    }
}
