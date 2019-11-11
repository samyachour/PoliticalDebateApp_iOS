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
}

struct PointsTableViewSection: AnimatableSectionModelType {
    var items: [SidedPointTableViewCellViewModel]
    var header = "" // Only using 1 section
    var identity: String { return header }

    init(items: [SidedPointTableViewCellViewModel]) {
        self.items = items
    }

    init(original: PointsTableViewSection, items: [SidedPointTableViewCellViewModel]) {
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
            markPointAsSeen(point: embeddedSidedPoints.first)
        case .embeddedRebuttals(let embeddedSidedPoints):
            sidedPointsRelay = .init(value: embeddedSidedPoints)
        case .standaloneRootPoints:
            sidedPointsRelay = .init(value: debate.sidedPoints)
            contextPointsDataSourceRelay = .init(value: debate.contextPoints)
            subscribeToContextPointsUpdates()
        }

        subscribeSidedPointsUpdates()
    }

    private let disposeBag = DisposeBag()
    let viewState: PointsTableViewState

    var debate: Debate
    var isStarred: Bool

    // MARK: - DataSource

    // Private

    private let sidedPointsRelay: BehaviorRelay<[Point]>
    private lazy var sidedPointsDataSourceRelay = BehaviorRelay<[PointsTableViewSection]>(value: [PointsTableViewSection(items: [])])

    private func subscribeSidedPointsUpdates() {
        sidedPointsRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] points in
                guard let debatePrimaryKey = self?.debate.primaryKey,
                    let viewState = self?.viewState,
                    let currentSidedPointsDataSourceSection = self?.sidedPointsDataSourceRelay.value.first else {
                        return
                }

                let newSidedPointCellViewModels = points
                    .map({ SidedPointTableViewCellViewModel(point: $0,
                                                            debatePrimaryKey: debatePrimaryKey,
                                                            useFullDescription: viewState.shouldCellsUseFullDescription) })
                self?.sidedPointsDataSourceRelay.accept([PointsTableViewSection(original: currentSidedPointsDataSourceSection,
                                                                                items: newSidedPointCellViewModels)])
        }).disposed(by: disposeBag)
    }

    // Internal

    lazy var sidedPointsDataSourceDriver = sidedPointsDataSourceRelay.asDriver()
    var sidedPointsCount: Int { return sidedPointsRelay.value.count }

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
                    .markBatchProgress(pointPrimaryKeys: contextPoints.map { $0.primaryKey },
                                       debatePrimaryKey: self.debate.primaryKey)
                    .subscribe() // Don't care if this call succeeds or fails
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }

    // Internal

    lazy var contextPointsDataSourceDriver = contextPointsDataSourceRelay?.asDriver()
    var shouldShowContextPointsView: Bool { return contextPointsDataSourceRelay?.value.isEmpty == false }

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
                 modelSelected: ControlEvent<SidedPointTableViewCellViewModel>,
                 undoSelected: ControlEvent<Void>) {
        switch viewState {
        case .standaloneRootPoints:
            modelSelected
            .subscribe(onNext: { [weak self] pointTableViewCellViewModel in
                guard let debate = self?.debate else { return }

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
    lazy var completedShowingTableViewRelay = PublishRelay<Void>()
    lazy var completedShowingTableViewSignal = completedShowingTableViewRelay.asSignal()

    func observe(completedShowingTableViewSignal: Signal<Void>) {
        completedShowingTableViewSignal
            .emit(to: completedShowingTableViewRelay)
            .disposed(by: disposeBag)
    }

    // MARK: - API calls

    // Private

    private func markPointAsSeen(point: Point?) {
        guard let point = point else { return }

        UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                            debatePrimaryKey: debate.primaryKey)
            .subscribe(onError: markPointAsSeenErrorHandler)
            .disposed(by: disposeBag)
    }

    private func markPointAsSeenErrorHandler(error: Error) {
        if let generalError = error as? GeneralError,
            generalError == .alreadyHandled {
            return
        }
        guard let moyaError = error as? MoyaError,
            let response = moyaError.response else {
                ErrorHandlerService.showBasicRetryErrorBanner()
                return
        }

        switch response.statusCode {
        case 404:
            ErrorHandlerService.showBasicReportErrorBanner()
        default:
            ErrorHandlerService.showBasicRetryErrorBanner()
        }
    }

}
