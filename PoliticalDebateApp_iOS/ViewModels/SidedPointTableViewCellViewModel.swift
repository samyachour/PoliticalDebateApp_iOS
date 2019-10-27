//
//  SidedPointTableViewCellViewModel.swift
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

struct SidedPointTableViewCellViewModel: IdentifiableType, Equatable {
    let point: Point
    let debatePrimaryKey: PrimaryKey
    let hasCompletedPaths: Bool
    let useFullDescription: Bool
    var backgroundColor: UIColor? {
        return point.side?.color
    }

    init(point: Point,
         debatePrimaryKey: PrimaryKey,
         seenPoints: [PrimaryKey]?,
         useFullDescription: Bool = false) {
        self.point = point
        self.debatePrimaryKey = debatePrimaryKey
        if let seenPoints = seenPoints,
            !seenPoints.isEmpty {
            hasCompletedPaths = SidedPointTableViewCellViewModel.deriveHasCompletedPaths(point, seenPoints)
        } else {
            hasCompletedPaths = false
        }
        self.useFullDescription = useFullDescription
    }

    // MARK: IdentifiableType

    typealias Identity = Int
    var identity: Int {
        return point.primaryKey
    }

    // MARK: Equatable

    static func == (lhs: SidedPointTableViewCellViewModel, rhs: SidedPointTableViewCellViewModel) -> Bool {
        return lhs.point == rhs.point
    }

    // MARK: - Helpers

    private static func deriveHasCompletedPaths(_ point: Point, _ seenPoints: [PrimaryKey]) -> Bool {
        // Base case
        guard let rebuttals = point.rebuttals,
            !rebuttals.isEmpty else {
            return seenPoints.contains(point.primaryKey)
        }
        // Recursively check for completion for the current point & its rebuttals
        return seenPoints.contains(point.primaryKey) && rebuttals.allSatisfy({
            seenPoints.contains($0.primaryKey) &&
            deriveHasCompletedPaths($0, seenPoints)
        })
    }
}
