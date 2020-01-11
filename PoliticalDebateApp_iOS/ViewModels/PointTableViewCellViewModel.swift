//
//  PointTableViewCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/24/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class PointTableViewCellViewModel: IdentifiableType, Equatable {
    let point: Point
    let debatePrimaryKey: PrimaryKey
    let useFullDescription: Bool
    var hasCompletedPaths: Bool
    let hasSeen: Bool
    let shouldFormatAsHeaderLabel: Bool
    let shouldShowSeparator: Bool
    let isRootPoint: Bool
    let bubbleTailSide: BubbleTailSide

    var description: String { useFullDescription == true ? point.description : point.shortDescription }
    var bubbleColor: UIColor? { point.side?.color(seen: hasSeen) }

    init(point: Point,
         debatePrimaryKey: PrimaryKey,
         useFullDescription: Bool = false,
         seenPoints: Set<PrimaryKey>? = nil,
         shouldFormatAsHeaderLabel: Bool = false,
         shouldShowSeparator: Bool = false,
         isRootPoint: Bool = false,
         bubbleTailSide: BubbleTailSide = .left) {
        self.point = point
        self.debatePrimaryKey = debatePrimaryKey
        self.useFullDescription = useFullDescription
        let seenPoints = seenPoints ?? UserDataManager.shared.getProgress(for: debatePrimaryKey).seenPoints
        hasCompletedPaths = Self.deriveHasCompletedPaths(point, seenPoints)
        hasSeen = seenPoints.contains(point.primaryKey) || useFullDescription // if they're seeing the full description, the point has been seen
        self.shouldFormatAsHeaderLabel = shouldFormatAsHeaderLabel
        self.shouldShowSeparator = shouldShowSeparator || point.side?.isContext == false
        self.isRootPoint = isRootPoint
        self.bubbleTailSide = bubbleTailSide
    }

    // MARK: IdentifiableType

    typealias Identity = Int
    var identity: Int { return point.primaryKey }

    // MARK: Equatable

    static func == (lhs: PointTableViewCellViewModel, rhs: PointTableViewCellViewModel) -> Bool {
        return lhs.point == rhs.point && lhs.hasCompletedPaths == rhs.hasCompletedPaths && lhs.hasSeen == rhs.hasSeen
    }

    // MARK: - Helpers

    private static func deriveHasCompletedPaths(_ currentPoint: Point, _ seenPoints: Set<PrimaryKey>) -> Bool {
        // Base case
        guard let rebuttals = currentPoint.rebuttals,
            !rebuttals.isEmpty else {
            return seenPoints.contains(currentPoint.primaryKey)
        }
        // Recursively check for completion for the current point & its rebuttals
        return seenPoints.contains(currentPoint.primaryKey) && rebuttals.allSatisfy({
            seenPoints.contains($0.primaryKey) &&
            deriveHasCompletedPaths($0, seenPoints)
        })
    }
}

enum BubbleTailSide {
    case left
    case right

    static let defaultSide = BubbleTailSide.right
}
