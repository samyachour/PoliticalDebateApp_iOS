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
}

struct Point {
    let primaryKey: PrimaryKey
    let shortDescription: String
    let description: String
    let side: Side?
    let hyperlinks: [PointHyperlink]
    let images: [PointImage]
    let rebuttals: [Point]?
}

extension Point: Decodable {
    enum PointCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case shortDescription = "short_description"
        case description
        case side
        case hyperlinks
        case images
        case rebuttals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PointCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        shortDescription = try container.decode(String.self, forKey: .shortDescription)
        description = try container.decode(String.self, forKey: .description)
        side = Side(rawValue: try container.decode(String.self, forKey: .side).lowercased())
        hyperlinks = try container.decode([PointHyperlink].self, forKey: .hyperlinks)
        images = try container.decode([PointImage].self, forKey: .images)
        // We don't always have rebuttals
        rebuttals = try container.decodeIfPresent([Point].self, forKey: .rebuttals)
    }
}

extension Point: Equatable {
    static func == (lhs: Point, rhs: Point) -> Bool {
        // Our backend ensures if two points share a primary key they must be the same object
        return lhs.primaryKey == rhs.primaryKey
    }
}

struct PointImage {
    let url: URL
    let source: String
    let name: String?
}

extension PointImage: Decodable {
    enum PointImageCodingKeys: String, CodingKey {
        case url
        case source
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PointImageCodingKeys.self)

        url = try container.decode(URL.self, forKey: .url)
        source = try container.decode(String.self, forKey: .source)
        name = try container.decodeIfPresent(String.self, forKey: .name)
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
