//
//  APITests.swift
//  APITests
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import XCTest
import RxSwift
@testable import PoliticalDebateApp_iOS

class APITests: XCTestCase {

    private let disposeBag = DisposeBag()

    override func setUp() {}

    override func tearDown() {}

    // There's no need to write tests for the Auth API only the token requests have responses
    // Can't even simulate session management in XCTest so no point, will be covered by UITests

    func testGetSingleDebate() {
        let testAPI = NetworkService<DebateAPI>()
        testAPI.makeTestRequest(with: .debate(primaryKey: 2))
            .map(Debate.self)
            .subscribe(onSuccess: { debate in
                XCTAssert(debate.title == "test_debate")
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllDebates() {
        let testAPI = NetworkService<DebateAPI>()
        testAPI.makeTestRequest(with: .debateSearch(searchString: ""))
            .map([Debate].self)
            .subscribe(onSuccess: { debates in
                XCTAssert(debates[1].primaryKey == 2)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetSingleDebateProgressPoints() {
        let testAPI = NetworkService<ProgressAPI>()
        testAPI.makeTestRequest(with: .loadProgress(debatePrimaryKey: 1))
            .map(Progress.self)
            .subscribe(onSuccess: { progress in
                XCTAssert(progress.debatePrimaryKey == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllDebateProgressPoints() {
        let testAPI = NetworkService<ProgressAPI>()
        testAPI.makeTestRequest(with: .loadAllProgress)
            .map([Progress].self)
            .subscribe(onSuccess: { (progressPoints) in
                XCTAssert(progressPoints[0].debatePrimaryKey == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllStarredDebates() {
        let testAPI = NetworkService<StarredAPI>()
        testAPI.makeTestRequest(with: .loadAllStarred)
            .map(Starred.self)
            .subscribe(onSuccess: { (starred) in
                XCTAssert(starred.starredList[0] == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

}
