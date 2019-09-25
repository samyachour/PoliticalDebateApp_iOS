//
//  DebatesCollectionViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class DebatesCollectionViewModel {

    // MARK: - Datasource

    private let debatesDataSourceRelay = BehaviorRelay<[DebateCollectionViewCellViewModel]>(value: [])
    lazy var sharedDebatesDataSourceRelay = debatesDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    let debatesRetrievalErrorRelay = PublishRelay<Error>()

    // Used to filter the latest debates array through our starred & progress user data
    // and do local sorting if applicable
    private func acceptNewDebates(_ debates: [Debate], sortSelection: SortByOption) {

        var newDebateCollectionViewCellViewModels = debates.map { debate -> DebateCollectionViewCellViewModel in
            let completedPercentage = UserDataManager.shared.getProgress(for: debate.primaryKey).completedPercentage
            let isStarred = UserDataManager.shared.isStarred(debate.primaryKey)
            return DebateCollectionViewCellViewModel(debate: debate,
                                                     completedPercentage: completedPercentage,
                                                     isStarred: isStarred)
        }
        switch sortSelection {
        case .progressAscending:
            newDebateCollectionViewCellViewModels.sort { $0.completedPercentage < $1.completedPercentage }
        case .progressDescending:
            newDebateCollectionViewCellViewModels.sort { $0.completedPercentage > $1.completedPercentage }
        default:
            break
        }
        debatesDataSourceRelay.accept(newDebateCollectionViewCellViewModels)
    }

    func refreshDebatesWithLocalData() {
        guard !debatesDataSourceRelay.value.isEmpty else { return } // no point in refreshing 0 debates

        let newDebateCollectionViewCellViewModels = debatesDataSourceRelay.value.map { (debateCollectionViewCellViewModel) -> DebateCollectionViewCellViewModel in
            let primaryKey = debateCollectionViewCellViewModel.debate.primaryKey
            debateCollectionViewCellViewModel.completedPercentage = UserDataManager.shared.getProgress(for: primaryKey).completedPercentage
            debateCollectionViewCellViewModel.isStarred = UserDataManager.shared.isStarred(primaryKey)

            return debateCollectionViewCellViewModel
        }

        debatesDataSourceRelay.accept(newDebateCollectionViewCellViewModels)
    }

    // MARK: - Input handling

    private let disposeBag = DisposeBag()

    func subscribeToManualDebateUpdates(_ searchTriggeredDriver: Driver<String>,
                                        _ sortSelectionDriver: Driver<SortByOption>,
                                        _ manualRefreshDriver: Driver<Void>) {
        let searchAndSortDriver = Driver
            .combineLatest(searchTriggeredDriver,
                           sortSelectionDriver) { return ($0, $1) }
            .distinctUntilChanged({ (lhs, rhs) -> Bool in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            })

        Driver
            .combineLatest(searchAndSortDriver,
                           manualRefreshDriver) { (searchAndSortValue, _) -> (String, SortByOption) in
                                // Manual refresh can be ignored since it just uses the latest search and sort values
                                return searchAndSortValue
            }
            .debounce(0.3)
            .drive(onNext: { [weak self] (searchString, sortSelection) in
                self?.retrieveDebates(searchString: searchString, sortSelection: sortSelection)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

    private func retrieveDebates(searchString: String, sortSelection: SortByOption) {
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
