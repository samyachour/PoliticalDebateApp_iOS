//
//  DebatesTableViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift

struct DebatesTableViewSection: AnimatableSectionModelType {
    var items: [DebateTableViewCellViewModel]
    var header = "" // Only using 1 section
    var identity: String { return header }

    init(items: [DebateTableViewCellViewModel]) {
        self.items = items
    }

    init(original: DebatesTableViewSection, items: [DebateTableViewCellViewModel]) {
        self = original
        self.items = items
    }
}

class DebatesTableViewModel {

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

    private lazy var debatesDataSourceRelay = BehaviorRelay<[DebatesTableViewSection]?>(value: nil)
    /// When we want to propogate errors, we can't do it through the viewModelRelay
    /// or else it will complete and the value will be invalidated
    private lazy var debatesRetrievalErrorRelay = PublishRelay<Error>()
    private lazy var refreshDebatesWithLocalDataRelay = PublishRelay<Void>()

    private func createNewDebateCellViewModel(debate: Debate) -> DebateTableViewCellViewModel {
        let completedPercentage = UserDataManager.shared.getProgress(for: debate.primaryKey).calculateCompletedPercentage(totalPoints: debate.totalPoints)
        // Always new instances so we don't modify objects of the array we're mapping
        return DebateTableViewCellViewModel(debate: debate,
                                            completedPercentage: completedPercentage,
                                            isStarred: UserDataManager.shared.isStarred(debate.primaryKey))
    }

    /// Used to filter the latest debates array through our starred & progress user data
    /// and do local sorting if applicable
    private func acceptNewDebates(_ debates: [Debate], sortSelection: SortByOption) {
        let currentDebatesDataSourceSection = debatesDataSourceRelay.value?.first ?? DebatesTableViewSection(items: [])

        var newDebateTableViewCellViewModels = debates.map(createNewDebateCellViewModel)

        switch sortSelection {
        case .progressAscending:
            newDebateTableViewCellViewModels.sort { $0.completedPercentage < $1.completedPercentage }
        case .progressDescending:
            newDebateTableViewCellViewModels.sort { $0.completedPercentage > $1.completedPercentage }
        default:
            break
        }

        debatesDataSourceRelay.accept([DebatesTableViewSection(original: currentDebatesDataSourceSection, items: newDebateTableViewCellViewModels)])
    }

    private func refreshDebatesWithLocalData() {
        // No point in refreshing 0 debates
        guard let currentDebatesDataSourceSection = debatesDataSourceRelay.value?.first,
            !currentDebatesDataSourceSection.items.isEmpty else {
                return
        }

        let newDebateTableViewCellViewModels = currentDebatesDataSourceSection.items
            .map({ $0.debate })
            .map(createNewDebateCellViewModel)

        debatesDataSourceRelay.accept([DebatesTableViewSection(original: currentDebatesDataSourceSection, items: newDebateTableViewCellViewModels)])
    }

    // Internal

    lazy var debatesDataSourceDriver = debatesDataSourceRelay.asDriver().filterNil()
    lazy var debatesRetrievalErrorSignal = debatesRetrievalErrorRelay.asSignal()

    func triggerRefreshDebatesWithLocalData() { refreshDebatesWithLocalDataRelay.accept(()) }

    // MARK: - Input handling

    typealias DebateRequest = (searchString: String?, sortSelection: SortByOption)
    private static let defaultSearchString = ""

    func subscribeToManualDebateUpdates(_ searchUpdatedSignal: Signal<DebatesTableViewController.UpdatedSearch>,
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
            .debounce(GeneralConstants.standardDebounceDuration)
            .emit(onNext: { [weak self] (searchString, sortSelection) in
                self?.retrieveDebates((searchString, sortSelection))
            }).disposed(by: disposeBag)
    }

    // MARK: - API calls

    // Private

    private let debateNetworkService = NetworkService<DebateAPI>()
    private var plainDebates: [Debate]?
    private var plainDebatesLastFetched: Date?

    private static func isDebateRequestPlain(_ debateRequest: DebateRequest) -> Bool {
        return (debateRequest.searchString ?? "").isEmpty && debateRequest.sortSelection == SortByOption.defaultValue
    }

    private func retrieveDebates(_ debateRequest: DebateRequest) {
        if let plainDebatesLastFetched = plainDebatesLastFetched,
            Date().timeIntervalSince(plainDebatesLastFetched) >= 60*60*24 { // if our plain debates data is more than 24 hrs old, reset
            plainDebates = nil
        }
        guard plainDebates == nil || !Self.isDebateRequestPlain(debateRequest) else {
            if let plainDebates = plainDebates { acceptNewDebates(plainDebates, sortSelection: SortByOption.defaultValue) }
            return
        }

        debateNetworkService.makeRequest(with: .debateFilter(searchString: debateRequest.searchString ?? Self.defaultSearchString,
                                                             filter: debateRequest.sortSelection))
            .map([Debate].self)
            .flatMap({ debates -> Single<[Debate]> in
                return UserDataManager.shared.userDataLoadedSingle
                    .map { _ in return debates } // don't care if user data loaded successfully, but want to wait anyway in case it did
            })
            .subscribe(onSuccess: { [weak self] debates in
                self?.acceptNewDebates(debates, sortSelection: debateRequest.sortSelection)
                if Self.isDebateRequestPlain(debateRequest) {
                    self?.plainDebates = debates
                    self?.plainDebatesLastFetched = Date()
                }
            }) { [weak self] error in
                self?.debatesRetrievalErrorRelay.accept(error)
        }.disposed(by: disposeBag)
    }

    // Internal

    func retrieveFullDebate(_ primaryKey: PrimaryKey) -> Single<Debate> {
        return debateNetworkService.makeRequest(with: .debate(primaryKey: primaryKey))
            .map(Debate.self)
    }

}

enum SortByOption: Int, CaseIterable {
    case lastUpdated
    case random
    case starred
    case noProgress
    case progressAscending
    case progressDescending

    var stringValue: String {
        switch self {
        case .lastUpdated: return "Date"
        case .random: return "Shuffle"
        case .starred: return "Starred"
        case .noProgress: return "Unread"
        case .progressAscending: return "<"
        case .progressDescending: return ">"
        }
    }

    static let defaultValue: SortByOption = .lastUpdated
}
