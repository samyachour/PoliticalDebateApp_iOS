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
}

enum SortByOption: Int, CaseIterable {
    case sortBy
    case lastUpdated
    case starred
    case progress
    case noProgress

    var stringValue: String {
        switch self {
        case .sortBy: return "Sort by"
        case .lastUpdated: return "Last updated"
        case .starred: return "Starred"
        case .progress: return "Progress"
        case .noProgress: return "No progress"
        }
    }

    var selectionColor: UIColor {
        switch self {
        case .sortBy: return GeneralColors.softButton
        default: return GeneralColors.hardButton
        }
    }
}
