//
//  DebatesListViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class DebateListViewModel {

    // MARK: - Observables

    private let disposeBag = DisposeBag()

    let debatesViewModelRelay = BehaviorRelay<[DebateCellViewModel]>(value: [])
    let debatesRetrievalErrorRelay = PublishRelay<Error>()

    // Used to filter the latest debates array through our starred & progress user data
    // and do local sorting if it applies
    func acceptNewDebates(_ debates: [Debate], sortSelection: SortByOption) {

        let latestStarred = UserDataManager.shared.starred
        let latestProgress = UserDataManager.shared.progress

        var newDebateViewModels = debates.map { debate -> DebateCellViewModel in
            let completedPercentage = latestProgress.first(where: {$0.debatePrimaryKey == debate.primaryKey})?.completedPercentage ?? 0
            let isStarred = latestStarred.contains(debate.primaryKey)
            return DebateCellViewModel(debate: debate,
                                       completedPercentage: completedPercentage,
                                       isStarred: isStarred)
        }
        switch sortSelection {
        case .progressAscending:
            newDebateViewModels.sort { $0.completedPercentage > $1.completedPercentage }
        case .progressDescending:
            newDebateViewModels.sort { $0.completedPercentage < $1.completedPercentage }
        default:
            break
        }
        debatesViewModelRelay.accept(newDebateViewModels)
    }

    // MARK: - Input handling

    func subscribeToSearchAndFilterUpdates(_ updateDebatesDriver: Driver<(String, SortByOption)>) {
        updateDebatesDriver
            .distinctUntilChanged({ (lhs, rhs) -> Bool in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            })
            .drive(onNext: { [weak self] (searchString, sortSelection) in
                self?.retrieveDebates(searchString: searchString, sortSelection: sortSelection)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

    func retrieveDebates(searchString: String, sortSelection: SortByOption) {
        debateNetworkService.makeRequest(with: .debateFilter(searchString: searchString, filter: sortSelection))
            .map([Debate].self)
            .subscribe(onSuccess: { [weak self] debates in
                self?.acceptNewDebates(debates, sortSelection: sortSelection)
            }) { [weak self] error in
                self?.debatesRetrievalErrorRelay.accept(error)
        }.disposed(by: disposeBag)
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

    static let defaultValue: SortByOption = .sortBy
}
