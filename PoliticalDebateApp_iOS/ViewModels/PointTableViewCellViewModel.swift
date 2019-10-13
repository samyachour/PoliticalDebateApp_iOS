//
//  PointTableViewCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/24/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

struct PointTableViewCellViewModel {
    let point: Point
    let debatePrimaryKey: PrimaryKey
    let hasCompletedPaths: Bool
    var backgroundColor: UIColor? {
        return point.side?.color
    }

    init(point: Point, debatePrimaryKey: PrimaryKey, seenPoints: [PrimaryKey]?) {
        self.point = point
        self.debatePrimaryKey = debatePrimaryKey
        if let seenPoints = seenPoints,
            !seenPoints.isEmpty {
            hasCompletedPaths = PointTableViewCellViewModel.deriveHasCompletedPaths(point, seenPoints)
        } else {
            hasCompletedPaths = false
        }
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
