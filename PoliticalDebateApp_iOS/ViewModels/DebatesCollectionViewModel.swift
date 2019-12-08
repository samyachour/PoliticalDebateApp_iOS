//
//  DebatesCollectionViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift

struct DebatesCollectionViewSection: AnimatableSectionModelType {
    var items: [DebateCollectionViewCellViewModel]
    var header = "" // Only using 1 section
    var identity: String { return header }

    init(items: [DebateCollectionViewCellViewModel]) {
        self.items = items
    }

    init(original: DebatesCollectionViewSection, items: [DebateCollectionViewCellViewModel]) {
        self = original
        self.items = items
    }
}

class DebatesCollectionViewModel {

    init() {
        UserDataManager.shared.userDataLoadedDriver
            .drive(onNext: { [weak self] loaded in
                guard loaded else { return }

                self?.triggerRefreshDebatesWithLocalData()
            }).disposed(by: disposeBag)

        refreshDebatesWithLocalDataRelay
            .asSignal()
            .debounce(GeneralConstants.standardDebounceDuration)
            .emit(onNext: { [weak self] _ in
                self?.refreshDebatesWithLocalData()
            }).disposed(by: disposeBag)
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    // Private

    private lazy var debatesDataSourceRelay = BehaviorRelay<[DebatesCollectionViewSection]?>(value: nil)
    /// When we want to propogate errors, we can't do it through the viewModelRelay
    /// or else it will complete and the value will be invalidated
    private lazy var debatesRetrievalErrorRelay = PublishRelay<Error>()
    private lazy var refreshDebatesWithLocalDataRelay = PublishRelay<Void>()

    private func createNewDebateCellViewModel(debate: Debate) -> DebateCollectionViewCellViewModel {
        UserDataManager.shared.removeStaleLocalPoints(from: debate)
        let completedPercentage = Int((Float(UserDataManager.shared.getProgress(for: debate.primaryKey).seenPoints.count) / Float(debate.totalPoints)) * 100)
        // Always new instances so we don't modify objects of the array we're mapping
        return DebateCollectionViewCellViewModel(debate: debate,
                                                 completedPercentage: completedPercentage,
                                                 isStarred: UserDataManager.shared.isStarred(debate.primaryKey))
    }

    /// Used to filter the latest debates array through our starred & progress user data
    /// and do local sorting if applicable
    private func acceptNewDebates(_ debates: [Debate], sortSelection: SortByOption) {
        let currentDebatesDataSourceSection = debatesDataSourceRelay.value?.first ?? DebatesCollectionViewSection(items: [])

        var newDebateCollectionViewCellViewModels = debates.map(createNewDebateCellViewModel)

        switch sortSelection {
        case .progressAscending:
            newDebateCollectionViewCellViewModels.sort { $0.completedPercentage < $1.completedPercentage }
        case .progressDescending:
            newDebateCollectionViewCellViewModels.sort { $0.completedPercentage > $1.completedPercentage }
        default:
            break
        }

        debatesDataSourceRelay.accept([DebatesCollectionViewSection(original: currentDebatesDataSourceSection, items: newDebateCollectionViewCellViewModels)])
    }

    private func refreshDebatesWithLocalData() {
        // No point in refreshing 0 debates
        guard let currentDebatesDataSourceSection = debatesDataSourceRelay.value?.first,
            !currentDebatesDataSourceSection.items.isEmpty else {
                return
        }

        let newDebateCollectionViewCellViewModels = currentDebatesDataSourceSection.items
            .map({ $0.debate })
            .map(createNewDebateCellViewModel)

        debatesDataSourceRelay.accept([DebatesCollectionViewSection(original: currentDebatesDataSourceSection, items: newDebateCollectionViewCellViewModels)])
    }

    // Internal

    lazy var debatesDataSourceDriver = debatesDataSourceRelay.asDriver().filterNil()
    lazy var debatesRetrievalErrorSignal = debatesRetrievalErrorRelay.asSignal()

    func triggerRefreshDebatesWithLocalData() { refreshDebatesWithLocalDataRelay.accept(()) }

    // MARK: - Input handling

    typealias DebateRequest = (searchString: String?, sortSelection: SortByOption)
    private static let defaultSearchString = ""

    func subscribeToManualDebateUpdates(_ searchUpdatedSignal: Signal<DebatesCollectionViewController.UpdatedSearch>,
                                        _ sortSelectionSignal: Signal<SortByOption>,
                                        _ manualRefreshSignal: Signal<Void>) {
        let searchTriggeredRequestSignal = searchUpdatedSignal
            .filter({ $0.manual }) // only from manually triggered searches
            .map({ $0.searchString })
            .withLatestFrom(sortSelectionSignal.startWith(SortByOption.defaultValue)) { ($0, $1) }
            .map({ (searchString, sortSelection) -> DebateRequest in
                return (searchString, sortSelection)
        })
        let sortSelectionRequestSignal = sortSelectionSignal
            .withLatestFrom(searchUpdatedSignal.startWith((nil, false)).map({ $0.searchString })) { ($0, $1) }
            .map({ (sortSelection, searchString) -> DebateRequest in
                return (searchString, sortSelection)
        })
        let manualRefreshRequestSignal = manualRefreshSignal
            .withLatestFrom(searchUpdatedSignal.startWith((nil, false)).map({ $0.searchString })) { $1 }
            .withLatestFrom(sortSelectionSignal.startWith(SortByOption.defaultValue)) { ($0, $1) }
            .map { (searchString, sortSelection) -> DebateRequest in
                return (searchString, sortSelection)
        }

        let searchOrSortRequestSignal = Signal
            .merge(searchTriggeredRequestSignal, sortSelectionRequestSignal)
            .distinctUntilChanged({ (lhs, rhs) -> Bool in
                return lhs.0 == rhs.0 && lhs.1 == rhs.1
            })
        Signal.merge(searchOrSortRequestSignal, manualRefreshRequestSignal)
            .startWith((Self.defaultSearchString, SortByOption.defaultValue)) // initial request
            .emit(onNext: { [weak self] (searchString, sortSelection) in
                self?.retrieveDebates((searchString, sortSelection))
            }).disposed(by: disposeBag)
    }

    // MARK: - API calls

    private let debateNetworkService = NetworkService<DebateAPI>()

    private func retrieveDebates(_ debateRequest: DebateRequest) {
        debateNetworkService.makeRequest(with: .debateFilter(searchString: debateRequest.searchString ?? Self.defaultSearchString,
                                                             filter: debateRequest.sortSelection))
            .map([Debate].self)
            .flatMap({ debates -> Single<[Debate]> in
                return UserDataManager.shared.userDataLoadedSingle
                    .map { _ in return debates } // don't care if user data loaded successfully, but want to wait anyway in case it did
            })
            .subscribe(onSuccess: { [weak self] debates in
                self?.acceptNewDebates(debates, sortSelection: debateRequest.sortSelection)
            }) { [weak self] error in
                self?.debatesRetrievalErrorRelay.accept(error)
        }.disposed(by: disposeBag)
    }

}

enum SortByOption: Int, CaseIterable {
    case sortBy // backend returns last updated by default
    case lastUpdated
    case random
    case starred
    case progressAscending
    case progressDescending
    case noProgress

    var stringValue: String {
        switch self {
        case .sortBy: return "Sort by"
        case .lastUpdated: return "Last updated"
        case .random: return "Random"
        case .starred: return "Starred"
        case .progressAscending: return "Progress: Low to High"
        case .progressDescending: return "Progress: High to Low"
        case .noProgress: return "No progress"
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
