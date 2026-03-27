//
//  MasalAmcaUITests.swift
//  MasalAmcaUITests
//

import XCTest

final class MasalAmcaUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
