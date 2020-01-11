//
//  DebateTableViewCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class DebateTableViewCellViewModel: StarrableViewModel, IdentifiableType, Equatable {
    let debate: Debate
    var completedPercentage: Int
    var isStarred: Bool
    var formattedTags: String {
        let tagsList = debate.tags
            .components(separatedBy: ", ")
            .map({ $0.uppercased() })
        return (tagsList.count > Self.maxTagsCount ?
            tagsList[0...(Self.maxTagsCount - 1)] :
            tagsList[0...(tagsList.count - 1)])
            .joined(separator: ", ")
    }
    private static let maxTagsCount = 3

    init(debate: Debate, completedPercentage: Int, isStarred: Bool) {
        self.debate = debate
        self.completedPercentage = completedPercentage
        self.isStarred = isStarred
    }

    // MARK: IdentifiableType

    typealias Identity = Int
    var identity: Int { return debate.primaryKey }

    // MARK: Equatable

    static func == (lhs: DebateTableViewCellViewModel, rhs: DebateTableViewCellViewModel) -> Bool {
        return lhs.debate == rhs.debate &&
            lhs.completedPercentage == rhs.completedPercentage &&
            lhs.isStarred == rhs.isStarred &&
            lhs.debate.title == rhs.debate.title
    }
}
