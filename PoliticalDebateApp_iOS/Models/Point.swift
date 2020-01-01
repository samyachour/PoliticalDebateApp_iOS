//
//  Point.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/10/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

enum Side: String {
    case pro
    case con
    case context

    var color: UIColor {
        switch self {
        case .pro:
            return .customLightBlue
        case .con:
            return .customLightRed
        case .context:
            return .clear
        }
    }

    var isContext: Bool {
        switch self {
        case .context:
            return true
        case .pro,
             .con:
            return false
        }
    }
}

struct Point {
    let primaryKey: PrimaryKey
    let shortDescription: String
    let description: String
    let side: Side?
    let hyperlinks: [PointHyperlink]
    let rebuttals: [Point]?
}

extension Point: Decodable {
    enum PointCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case shortDescription = "short_description"
        case description
        case side
        case hyperlinks
        case rebuttals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PointCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        shortDescription = try container.decode(String.self, forKey: .shortDescription)
        description = try container.decode(String.self, forKey: .description)
        side = Side(rawValue: try container.decode(String.self, forKey: .side).lowercased())
        hyperlinks = try container.decode([PointHyperlink].self, forKey: .hyperlinks)
        // We don't always have rebuttals
        rebuttals = try container.decodeIfPresent([Point].self, forKey: .rebuttals)
    }
}

extension Point: Equatable {
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.primaryKey == rhs.primaryKey
    }
}

struct PointHyperlink {
    let substring: String
    let url: URL

    init(substring: String, url: URL) {
        self.substring = substring
        self.url = url
    }
}

extension PointHyperlink: Decodable {
    enum PointHyperlinkCodingKeys: String, CodingKey {
        case substring
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PointHyperlinkCodingKeys.self)

        substring = try container.decode(String.self, forKey: .substring)
        url = try container.decode(URL.self, forKey: .url)
    }
}
