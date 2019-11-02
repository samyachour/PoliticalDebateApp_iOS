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

class SidedPointTableViewCellViewModel: IdentifiableType, Equatable {
    let point: Point
    let debatePrimaryKey: PrimaryKey
    let useFullDescription: Bool
    var backgroundColor: UIColor? {
        return point.side?.color
    }

    init(point: Point,
         debatePrimaryKey: PrimaryKey,
         useFullDescription: Bool = false) {
        self.point = point
        self.debatePrimaryKey = debatePrimaryKey
        self.useFullDescription = useFullDescription
    }

    // MARK: Reacting to updates

    // Need to observe global progress state to avoid reloading entire table
    lazy var shouldShowCheckImageDriver = UserDataManager.shared.allProgressDriver
        .map({ [weak self] allProgress -> Bool in
            guard let point = self?.point,
                let seenPoints = allProgress[self?.debatePrimaryKey]?.seenPoints else {
                    return false
            }

            return Self.deriveHasCompletedPaths(point, seenPoints)
        })

    // MARK: IdentifiableType

    typealias Identity = Int
    var identity: Int { return point.primaryKey }

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
