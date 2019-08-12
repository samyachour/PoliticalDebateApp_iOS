//
//  DebatesListViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift

class DebateListViewModel {

    // MARK: - Observables
    private let disposeBag = DisposeBag()

    // MARK: - API calls

    // TODO: Load all starred and all progress then manually filter

    func subscribeToSearchAndSortQueries(searchInput: PublishSubject<String>, sortSelection: Driver<SortByOption>) {
        // TODO: Hit search API endpoint which should then update collectionView
        // Show status message on error

        // Just until I set it up fully
        sortSelection.drive(onNext: nil, onCompleted: nil).disposed(by: disposeBag)
    }

    let debatesRelay = BehaviorRelay<[DebateCellViewModel]>(value: DebateListViewModel.generateTestDebates(20))

    private static func generateTestDebates(_ count: Int) -> [DebateCellViewModel] { // TODO: To remove
        var returnArr = [DebateCellViewModel]()
        for _ in 0...count {
            returnArr.append(DebateCellViewModel(debate: Debate(primaryKey: 1,
                                                                title: "Test title words words words words words words words",
                                                                shortTitle: "Titl",
                                                                lastUpdated: nil,
                                                                totalPoints: 2,
                                                                debateMap: nil),
                                                 completedPercentage: Float.random(in: 0...1.0),
                                                 isStarred: Bool.random()))
        }
        return returnArr
    }
}

enum SortByOption: Int, CaseIterable {
    case sortBy // backend returns last updated by default
    case lastUpdated
    case starred
    case progressAscending
    case progressDescending
    case noProgress
    case random

    var stringValue: String {
        switch self {
        case .sortBy: return "Sort by"
        case .lastUpdated: return "Last updated"
        case .starred: return "Starred"
        case .progressAscending: return "Progress: Low to High"
        case .progressDescending: return "Progress: High to Low"
        case .noProgress: return "No progress"
        case .random: return "Random"
        }
    }

    var selectionColor: UIColor {
        switch self {
        case .sortBy: return GeneralColors.softButton
        default: return GeneralColors.hardButton
        }
    }
}
