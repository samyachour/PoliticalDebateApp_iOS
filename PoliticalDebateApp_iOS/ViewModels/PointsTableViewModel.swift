//
//  PointsTableViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/18/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxDataSources
import RxSwift

enum PointsTableViewState {
    case standaloneRootPoints
    case embeddedPointHistory(embeddedSidedPoints: [Point])
    case embeddedRebuttals(embeddedSidedPoints: [Point])

    var shouldCellsUseFullDescription: Bool {
        switch self {
        case .embeddedPointHistory:
            return true
        case .embeddedRebuttals,
             .standaloneRootPoints:
            return false
        }
    }

    var isStandaloneRootPoints: Bool {
        switch self {
        case .standaloneRootPoints:
            return true
        case .embeddedPointHistory,
             .embeddedRebuttals:
            return false
        }
    }
}

struct PointsTableViewSection: AnimatableSectionModelType {
    var items: [PointTableViewCellViewModel]
    var header = "" // Only using 1 section
    var identity: String { return header }

    init(items: [PointTableViewCellViewModel]) {
        self.items = items
    }

    init(original: PointsTableViewSection, items: [PointTableViewCellViewModel]) {
        self = original
        self.items = items
    }
}

class PointsTableViewModel: StarrableViewModel {

    init(debate: Debate,
         isStarred: Bool = false,
         viewState: PointsTableViewState) {
        self.debate = debate
        self.isStarred = isStarred
        self.viewState = viewState

        switch viewState {
        case .embeddedPointHistory(let embeddedSidedPoints):
            sidedPointsRelay = .init(value: embeddedSidedPoints)
            initialPointSide = embeddedSidedPoints.first?.side
            markPointAsSeen(point: embeddedSidedPoints.first)
        case .embeddedRebuttals(let embeddedSidedPoints):
            sidedPointsRelay = .init(value: embeddedSidedPoints)
            initialPointSide = embeddedSidedPoints.first?.side?.other
        case .standaloneRootPoints:
            sidedPointsRelay = .init(value: debate.sidedPoints)
            initialPointSide = .context
            contextPointsDataSourceRelay = .init(value: debate.contextPoints)
            subscribeToContextPointsUpdates()
        }

        subscribePointsUpdates()
        subscribeToProgressUpdates()
    }

    private let disposeBag = DisposeBag()
    let viewState: PointsTableViewState

    var debate: Debate
    var isStarred: Bool

    // MARK: - DataSource

    // Private

    private let sidedPointsRelay: BehaviorRelay<[Point]>
    private lazy var pointsDataSourceRelay = BehaviorRelay<[PointsTableViewSection]>(value: [PointsTableViewSection(items: [])])
    private let initialPointSide: Side?

    private func subscribePointsUpdates() {
        var pointsDriver = sidedPointsRelay.asDriver()
        if let contextPointsDriver = contextPointsDataSourceRelay?.asDriver() {
            pointsDriver = Driver.combineLatest(contextPointsDriver, pointsDriver)
                .map({ $0.0 + $0.1 })
        }

        pointsDriver
            .distinctUntilChanged()
            .drive(onNext: { [weak self] newPoints in
                guard let self = self,
                    let currentPointsDataSourceSection = self.pointsDataSourceRelay.value.first else {
                        return
                }

                var points = newPoints
                self.addDummyPointIfNeeded(&points)
                let newPointCellViewModels = points
                    .map({ PointTableViewCellViewModel(point: $0,
                                                       debatePrimaryKey: self.debate.primaryKey,
                                                       useFullDescription: self.viewState.shouldCellsUseFullDescription ||
                                                        $0.side?.isContext == true,
                                                       isRootPoint: self.viewState.isStandaloneRootPoints,
                                                       bubbleTailSide: $0.side?.bubbleTailSide(initial: self.initialPointSide)
                                                        ?? BubbleTailSide.defaultSide) })
                self.pointsDataSourceRelay.accept([PointsTableViewSection(original: currentPointsDataSourceSection,
                                                                          items: self.addHeaderContextPointCellViewModel(newPointCellViewModels))])
        }).disposed(by: disposeBag)
    }

    private func addDummyPointIfNeeded(_ points: inout [Point]) {
        switch viewState {
        case .embeddedRebuttals:
            // There is a UITextView bug where the first tableView cell with a UITextView has a delay
            // in loading the text, so we insert a dummy point with zero height to "take the fall"
            let dummyPoint = Point(primaryKey: -1, shortDescription: "", description: "", side: nil, hyperlinks: [], rebuttals: nil)
            points.insert(dummyPoint, at: 0)
        case .embeddedPointHistory,
             .standaloneRootPoints:
            break
        }
    }

    private func addHeaderContextPointCellViewModel(_ pointCellViewModels: [PointTableViewCellViewModel]) -> [PointTableViewCellViewModel] {
        var pointCellViewModelsWithHeader = pointCellViewModels
        guard viewState.isStandaloneRootPoints,
            let lastContextIndex = pointCellViewModels.firstIndex(where: { !($0.point.side?.isContext ?? false) }) else {
            return pointCellViewModels
        }

        let headerPoint = Point(primaryKey: -1, shortDescription: "", description: "Pro 🔵 / Con 🔴 main arguments", side: .context, hyperlinks: [], rebuttals: nil)
        let headerPointCellViewModel = PointTableViewCellViewModel(point: headerPoint,
                                                                   debatePrimaryKey: debate.primaryKey,
                                                                   useFullDescription: true,
                                                                   shouldFormatAsHeaderLabel: true,
                                                                   shouldShowSeparator: true)
        pointCellViewModelsWithHeader.insert(headerPointCellViewModel, at: lastContextIndex)
        return pointCellViewModelsWithHeader
    }

    // Internal

    lazy var pointsDataSourceDriver = pointsDataSourceRelay.asDriver()
    var pointsCount: Int { return sidedPointsRelay.value.count + (contextPointsDataSourceRelay?.value.count ?? 0) }

    // MARK: Standalone dataSource

    // Private

    private var contextPointsDataSourceRelay: BehaviorRelay<[Point]>?
    private lazy var contextPointsDataSourceSingle = contextPointsDataSourceRelay?.take(1).asSingle()

    private func subscribeToContextPointsUpdates() {
        contextPointsDataSourceSingle?
            .flatMap({ (contextPoints) -> Single<[Point]> in
                return UserDataManager.shared.userDataLoadedSingle
                    .map { loaded in return loaded ? contextPoints : [] }
            })
            .subscribe(onSuccess: { [weak self] contextPoints in
                guard let self = self else { return }

                UserDataManager.shared
                    .markBatchProgress(pointPrimaryKeys: Set(contextPoints.map { $0.primaryKey }),
                                       debatePrimaryKey: self.debate.primaryKey)
                    .subscribe() // Don't care if this call succeeds or fails
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }

    // MARK: - Reacting to updates

    private func subscribeToProgressUpdates() {
        UserDataManager.shared.allProgressDriver
            .drive(onNext: { [weak self] allProgress in
                guard let self = self,
                    let seenPoints = allProgress[self.debate.primaryKey]?.seenPoints,
                    let currentPointsDataSourceSection = self.pointsDataSourceRelay.value.first else {
                    return
                }

                var points = self.sidedPointsRelay.value
                if let contextPoints = self.contextPointsDataSourceRelay?.value {
                    points = contextPoints + points
                }
                self.addDummyPointIfNeeded(&points)
                let newPointCellViewModels = points
                    .map({ PointTableViewCellViewModel(point: $0,
                                                       debatePrimaryKey: self.debate.primaryKey,
                                                       useFullDescription: self.viewState.shouldCellsUseFullDescription ||
                                                        $0.side?.isContext == true,
                                                       seenPoints: seenPoints,
                                                       isRootPoint: self.viewState.isStandaloneRootPoints,
                                                       bubbleTailSide: $0.side?.bubbleTailSide(initial: self.initialPointSide)
                                                        ?? BubbleTailSide.defaultSide) })
                self.pointsDataSourceRelay.accept([PointsTableViewSection(original: currentPointsDataSourceSection,
                                                                          items: self.addHeaderContextPointCellViewModel(newPointCellViewModels))])
            }).disposed(by: disposeBag)
    }

    typealias ProgressUpdate = (seenPoints: Int, totalPoints: Int, completedPercentage: Int)
    var progressDriver: Driver<ProgressUpdate> {
        UserDataManager.shared.allProgressDriver
            .map({ [weak self] allProgress -> ProgressUpdate in
                guard let debate = self?.debate,
                    let progress = allProgress[debate.primaryKey] else {
                        return (0,0,0)
                }

                return (progress.seenPoints.count, debate.totalPoints, progress.calculateCompletedPercentage(totalPoints: debate.totalPoints))
            })
    }

    // MARK: - Points tables synchronization

    // MARK: Adding to point history

    // Private

    private lazy var newPointRelay = PublishRelay<Point>()

    // Internal

    lazy var newPointSignal = newPointRelay.asSignal()

    func observe(newPointSignal: Signal<Point>) {
        newPointSignal.emit(onNext: { [weak self] newPoint in
            guard let currentSidedPoints = self?.sidedPointsRelay.value else {
                    return
            }

            self?.sidedPointsRelay.accept(currentSidedPoints + [newPoint])
            self?.newRebuttalsRelay.accept(newPoint.rebuttals ?? [])
            self?.markPointAsSeen(point: newPoint)
        }).disposed(by: disposeBag)
    }

    // MARK: Updating rebuttals

    // Private

    private lazy var newRebuttalsRelay = PublishRelay<[Point]>()

    // Internal

    lazy var newRebuttalsSignal = newRebuttalsRelay.asSignal()

    func observe(newRebuttalsSignal: Signal<[Point]>) {
        newRebuttalsSignal.emit(to: sidedPointsRelay).disposed(by: disposeBag)
    }

    // MARK: Handling point selection

    // Private

    private lazy var viewControllerToPushRelay = PublishRelay<UIViewController>()
    private lazy var popSelfViewControllerRelay = PublishRelay<Void>()

    // Internal

    lazy var viewControllerToPushSignal = viewControllerToPushRelay.asSignal()
    lazy var popSelfViewControllerSignal = popSelfViewControllerRelay.asSignal()

    func observe(indexPathSelected: ControlEvent<IndexPath>,
                 modelSelected: ControlEvent<PointTableViewCellViewModel>,
                 undoSelected: ControlEvent<Void>) {
        switch viewState {
        case .standaloneRootPoints:
            modelSelected
            .subscribe(onNext: { [weak self] pointTableViewCellViewModel in
                guard let debate = self?.debate,
                    pointTableViewCellViewModel.point.side?.isContext == false else {
                        return
                }

                self?.viewControllerToPushRelay
                    .accept(PointsNavigatorViewController(viewModel: PointsNavigatorViewModel(rootPoint: pointTableViewCellViewModel.point,
                                                                                              debate: debate)))
            }).disposed(by: disposeBag)
        case .embeddedPointHistory:
            indexPathSelected.subscribe(onNext: { [weak self] indexPath in
                guard let currentPoints = self?.sidedPointsRelay.value,
                    currentPoints.count > 1,
                    indexPath.row < currentPoints.endIndex - 1 else {
                    return
                }

                let newPoints = currentPoints[0...indexPath.row]
                self?.sidedPointsRelay.accept(Array(newPoints))
            }).disposed(by: disposeBag)

            modelSelected.subscribe(onNext: { [weak self] sidedPointTableViewCellViewModel in
                self?.newRebuttalsRelay.accept(sidedPointTableViewCellViewModel.point.rebuttals ?? [])
            }).disposed(by: disposeBag)

            undoSelected.subscribe(onNext: { [weak self] _ in
                guard let currentPoints = self?.sidedPointsRelay.value else { return }

                guard currentPoints.count > 1 else {
                    self?.popSelfViewControllerRelay.accept(())
                    return
                }

                let newPoints = currentPoints[0..<currentPoints.count - 1]
                self?.newRebuttalsRelay.accept(newPoints.last?.rebuttals ?? [])
                self?.sidedPointsRelay.accept(Array(newPoints))
            }).disposed(by: disposeBag)
        case .embeddedRebuttals:
            modelSelected.subscribe(onNext: { [weak self] sidedPointTableViewCellViewModel in
                self?.newPointRelay.accept(sidedPointTableViewCellViewModel.point)
            }).disposed(by: disposeBag)
        }
    }

    // MARK: Showing hidden bottom cells

    // Internal

    /// This acts as a producer for embeddedRebuttals and consumer for embeddedPointHistory
    lazy var completedRecomputingTableViewHeightRelay = PublishRelay<Void>()
    lazy var completedRecomputingTableViewHeightSignal = completedRecomputingTableViewHeightRelay.asSignal()

    func observe(completedRecomputingTableViewHeightSignal: Signal<Void>) {
        completedRecomputingTableViewHeightSignal
            .emit(to: completedRecomputingTableViewHeightRelay)
            .disposed(by: disposeBag)
    }

    // MARK: - API calls

    // Private

    private func markPointAsSeen(point: Point?) {
        guard let point = point else { return }

        UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                            debatePrimaryKey: debate.primaryKey)
            .subscribe(onError: { ErrorHandlerService.handleRequest(error: $0, withReportCode: 404) })
            .disposed(by: disposeBag)
    }

}

// MARK: - Side extension

private extension Side {
    func bubbleTailSide(initial: Side?) -> BubbleTailSide {
        return self == initial ? .right : .left
    }

    var other: Side {
        switch self {
        case .pro:
            return .con
        case .con:
            return .pro
        case .context:
            fatalError("There is no inverse to context points")
        }
    }
}
