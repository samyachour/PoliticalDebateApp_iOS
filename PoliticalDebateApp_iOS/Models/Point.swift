//
//  Point.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/10/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

enum Side: String {
    case pro
    case con
}

struct Point {
    let primaryKey: PrimaryKey
    let description: String
    let side: Side?
    let hyperlinks: [PointHyperlink]
    let images: [PointImage]
    let rebuttals: [Point]?
}

extension Point: Decodable {
    enum PointCodingKeys: String, CodingKey {
        case primaryKey = "pk"
        case description
        case side
        case hyperlinks
        case images
        case rebuttals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PointCodingKeys.self)

        primaryKey = try container.decode(PrimaryKey.self, forKey: .primaryKey)
        description = try container.decode(String.self, forKey: .description)
        side = Side(rawValue: try container.decode(String.self, forKey: .side))
        hyperlinks = try container.decode([PointHyperlink].self, forKey: .hyperlinks)
        images = try container.decode([PointImage].self, forKey: .images)
        // We don't always have rebuttals
        rebuttals = try container.decodeIfPresent([Point].self, forKey: .rebuttals)
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
