//
//  PoliticalDebateApp_iOSTests.swift
//  PoliticalDebateApp_iOSTests
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import XCTest
import RxSwift
@testable import PoliticalDebateApp_iOS

class PoliticalDebateApp_iOSTests: XCTestCase {

    private let disposeBag = DisposeBag()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetSingleDebate() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let testAPI = NetworkManager<DebateAPI>()
        testAPI.makeTestRequest(with: .debate(primaryKey: 1)).subscribe(onSuccess: { response in
            if let debate = try? JSONDecoder().decode(Debate.self, from: response.data) {
                XCTAssert(debate.title == "test_debate_pro")
            } else {
                XCTAssert(false)
            }
        }, onError: { _ in
            XCTAssert(false)
        }).disposed(by: disposeBag)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
