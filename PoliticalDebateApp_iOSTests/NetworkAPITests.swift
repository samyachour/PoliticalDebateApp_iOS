//
//  NetworkAPITests.swift
//  NetworkAPITests
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import XCTest
import RxSwift
@testable import PoliticalDebateApp_iOS

class NetworkAPITests: XCTestCase {

    private let disposeBag = DisposeBag()

    override func setUp() {}

    override func tearDown() {}

    // There's no need to write tests for the Auth API only the token requests have responses
    // Can't even simulate session management in XCTest so no point, will be covered by UITests

    // Cannot write core data API tests because for some reason the generated managed object
    // classes do not work when you use them from a different target, e.g.
    // Could not cast value of type 'PoliticalDebateApp_iOS.LocalStarred' (0x600002570910) to 'PoliticalDebateApp_iOSTests.LocalStarred' (0x11956e5d8).


    func testGetSingleDebate() {
        let testAPI = NetworkService<DebateAPI>()
        testAPI.makeRequest(with: .debate(primaryKey: 2))
            .map(Debate.self)
            .subscribe(onSuccess: { debate in
                XCTAssert(debate.title == "Test debate number #0")
                XCTAssert(debate.debateMap?[0].description == "Test point 1")
                XCTAssert(debate.debateMap?[0].images[0].source == "Test source")
                XCTAssert(debate.debateMap?[0].rebuttals?[0].primaryKey == 1)
            }, onError: { err in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllDebates() {
        let testAPI = NetworkService<DebateAPI>()
        testAPI.makeRequest(with: .debateFilter(searchString: nil, filter: nil))
            .map([Debate].self)
            .subscribe(onSuccess: { debates in
                XCTAssert(debates[0].primaryKey == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetSingleDebateProgressPoints() {
        let testAPI = NetworkService<ProgressAPI>()
        testAPI.makeRequest(with: .loadProgress(debatePrimaryKey: 1))
            .map(Progress.self)
            .subscribe(onSuccess: { progress in
                XCTAssert(progress.debatePrimaryKey == 1)
            }, onError: { err in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllDebateProgressPoints() {
        let testAPI = NetworkService<ProgressAPI>()
        testAPI.makeRequest(with: .loadAllProgress)
            .map([Progress].self)
            .subscribe(onSuccess: { (progressPoints) in
                XCTAssert(progressPoints[0].debatePrimaryKey == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testGetAllStarredDebates() {
        let testAPI = NetworkService<StarredAPI>()
        testAPI.makeRequest(with: .loadAllStarred)
            .map(Starred.self)
            .subscribe(onSuccess: { (starred) in
                XCTAssert(starred.starredList[0] == 1)
            }, onError: { _ in
                XCTAssert(false)
            }).disposed(by: disposeBag)
    }

    func testLogin() {
        SessionManager.shared.login(email: "test1@mail.com", password: "testing")
            .subscribe(onSuccess: { _ in
                XCTAssert(SessionManager.shared.isActiveRelay.value)
                SessionManager.shared.resumeSession() // load tokens from keychain
                XCTAssert(SessionManager.shared.isActiveRelay.value)
            }) { _ in
                XCTAssert(false)
        }.disposed(by: disposeBag)
    }

    func testLogout() {
        SessionManager.shared.login(email: "test1@mail.com", password: "testing")
            .subscribe(onSuccess: { _ in
                XCTAssert(SessionManager.shared.isActiveRelay.value)
                SessionManager.shared.logout()
                XCTAssert(!SessionManager.shared.isActiveRelay.value)
                SessionManager.shared.resumeSession() // try to load tokens from keychain
                XCTAssert(!SessionManager.shared.isActiveRelay.value)
            }) { _ in
                XCTAssert(false)
            }.disposed(by: disposeBag)
    }

}
