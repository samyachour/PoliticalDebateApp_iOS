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
    case embeddedPointHistory
    case embeddedRebuttals
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
         viewState: PointsTableViewState,
         embeddedSidedPoints: [Point]? = nil) {
        self.debate = debate
        self.isStarred = isStarred
        self.viewState = viewState
        self.embeddedSidedPoints = embeddedSidedPoints
        subscribeSidedPointsUpdates()
        subscribeToContextPointsUpdates()

        UserDataManager.shared.sharedUserDataLoadedRelay
            .subscribe(onNext: { [weak self] loaded in
                guard loaded else { return }

                self?.tableViewReloadRelay.accept(())
            }).disposed(by: disposeBag)
    }

    private let disposeBag = DisposeBag()
    let viewState: PointsTableViewState

    var debate: Debate
    var isStarred: Bool

    // MARK: - DataSource

    // Private

    private let sidedPointsDataSourceRelay = BehaviorRelay<[PointsTableViewSection]>(value: [PointsTableViewSection(items: [])])
    private lazy var sidedPointsRelay = BehaviorRelay<[Point]>(value: debate.sidedPoints ?? [])
    private var embeddedSidedPoints: [Point]?

    private func subscribeSidedPointsUpdates() {
        BehaviorRelay
            .combineLatest(sidedPointsRelay.distinctUntilChanged(),
                           tableViewReloadRelay,
                           resultSelector: { (points, _) in return points })
            .subscribe(onNext: { [weak self] points in
                guard let debatePrimaryKey = self?.debate.primaryKey,
                    let viewState = self?.viewState,
                    let currentSidedPointsDataSourceSection = self?.sidedPointsDataSourceRelay.value.first else {
                        return
                }

                let seenPoints = UserDataManager.shared.getProgress(for: debatePrimaryKey).seenPoints
                let newSidedPointCellViewModels = points
                    .map({ SidedPointTableViewCellViewModel(point: $0,
                                                            debatePrimaryKey: debatePrimaryKey,
                                                            seenPoints: seenPoints,
                                                            useFullDescription: viewState == .embeddedPointHistory) })
                self?.sidedPointsDataSourceRelay.accept([PointsTableViewSection(original: currentSidedPointsDataSourceSection,
                                                                                items: newSidedPointCellViewModels)])
        }).disposed(by: disposeBag)
    }

    // Internal

    lazy var sharedSidedPointsDataSourceRelay = sidedPointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()
    // When we want to propogate errors, we can't do it through the viewModelRelay
    // or else it will complete and the value will be invalidated
    lazy var pointsRetrievalErrorRelay = PublishRelay<Error>()
    lazy var tableViewReloadRelay = BehaviorRelay<Void>(value: ())
    var sidedPointsCount: Int { return sidedPointsRelay.value.count }

    // MARK: Standalone dataSource

    // Private

    private let contextPointsDataSourceRelay = BehaviorRelay<[Point]>(value: [])

    private func subscribeToContextPointsUpdates() {
        sharedContextPointsDataSourceRelay
            .take(1).asSingle()
            .flatMap({ (contextPoints) -> Single<[Point]> in
                guard !UserDataManager.shared.userDataLoaded else { return .just(contextPoints) }

                return UserDataManager.shared.sharedUserDataLoadedRelay
                    .take(1).asSingle()
                    .map { loaded in return loaded ? contextPoints : [] }
            })
            .subscribe(onSuccess: { [weak self] contextPoints in
                guard let self = self else { return }

                // Don't care if this call succeeds or fails
                UserDataManager.shared
                    .markBatchProgress(pointPrimaryKeys: contextPoints.map { $0.primaryKey },
                                       debatePrimaryKey: self.debate.primaryKey,
                                       totalPoints: self.debate.totalPoints)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }

    // Internal

    lazy var sharedContextPointsDataSourceRelay = contextPointsDataSourceRelay
        .skip(1) // empty array emission initialized w/ relay
        .share()

    // MARK: - Points tables synchronization

    // MARK: Adding to point history

    private lazy var newPointRelay = PublishRelay<Point>()
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

    private lazy var newRebuttalsRelay = PublishRelay<[Point]>()
    lazy var newRebuttalsSignal = newRebuttalsRelay.asSignal()

    func observe(newRebuttalsSignal: Signal<[Point]>) {
        newRebuttalsSignal.emit(to: sidedPointsRelay).disposed(by: disposeBag)
    }

    // MARK: Handling point selection

    private lazy var viewControllerToPushRelay = PublishRelay<UIViewController>()
    private lazy var popSelfViewControllerRelay = PublishRelay<Void>()

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

    // MARK: - API calls

    // Private

    private let debateNetworkService = NetworkService<DebateAPI>()

    private func markPointAsSeen(point: Point?) {
        guard let point = point else { return }

        UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                            debatePrimaryKey: debate.primaryKey,
                                            totalPoints: debate.totalPoints)
            .subscribe(onError: markPointAsSeenErrorHandler)
            .disposed(by: disposeBag)
    }

    private let markPointAsSeenErrorHandler: (Error) -> Void = { error in
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

    // Internal

    func retrieveAllDebatePoints() {
        switch viewState {
        case .embeddedPointHistory:
            markPointAsSeen(point: embeddedSidedPoints?.first)
            fallthrough
        case .embeddedRebuttals:
            guard let embeddedSidedPoints = embeddedSidedPoints else { return }

            sidedPointsRelay.accept(embeddedSidedPoints)
        case .standaloneRootPoints:
            // Only should load all debate points if we don't already have the debate map
            guard sidedPointsRelay.value.isEmpty else { return }

            debateNetworkService.makeRequest(with: .debate(primaryKey: debate.primaryKey))
            .map(Debate.self)
            .subscribe(onSuccess: { [weak self] debate in
                guard let sidedPoints = debate.sidedPoints,
                    let contextPoints = debate.contextPoints,
                    !sidedPoints.isEmpty else {
                        ErrorHandlerService.showBasicReportErrorBanner()
                        return
                }

                self?.sidedPointsRelay.accept(sidedPoints)
                self?.contextPointsDataSourceRelay.accept(contextPoints)
                self?.debate = debate
            }) { [weak self] error in
                self?.pointsRetrievalErrorRelay.accept(error)
            }.disposed(by: disposeBag)
        }
    }

}
