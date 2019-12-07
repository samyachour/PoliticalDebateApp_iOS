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
    var backgroundColor: UIColor? {
        return point.side?.color
    }
    var hasCompletedPaths: Bool

    init(point: Point,
         debatePrimaryKey: PrimaryKey,
         useFullDescription: Bool = false,
         seenPoints: [PrimaryKey]? = nil) {
        self.point = point
        self.debatePrimaryKey = debatePrimaryKey
        self.useFullDescription = useFullDescription
        hasCompletedPaths = Self.deriveHasCompletedPaths(point, seenPoints ?? UserDataManager.shared.getProgress(for: debatePrimaryKey).seenPoints)
    }

    // MARK: IdentifiableType

    typealias Identity = Int
    var identity: Int { return point.primaryKey }

    // MARK: Equatable

    static func == (lhs: PointTableViewCellViewModel, rhs: PointTableViewCellViewModel) -> Bool {
        return lhs.point == rhs.point && lhs.hasCompletedPaths == rhs.hasCompletedPaths
    }

    // MARK: - Helpers

    private static func deriveHasCompletedPaths(_ currentPoint: Point, _ seenPoints: [PrimaryKey]) -> Bool {
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
