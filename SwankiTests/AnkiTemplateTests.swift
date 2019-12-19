// Copyright © 2019 Brian's Brain. All rights reserved.

import Swanki
import XCTest

final class AnkiTemplateTests: XCTestCase {
  func testRenderPassthrough() {
    let template = AnkiTemplate(template: "This has no sections")
    XCTAssertEqual(try? template.render(), "This has no sections")
  }

  /// Truthy sections should have their contents rendered.
  func testTruthy() {
    let template = AnkiTemplate(template: "{{#boolean}}This should be rendered.{{/boolean}}")
    XCTAssertEqual(try? template.render(["boolean": true]), "This should be rendered.")
  }

  /// Falsey sections should have their contents omitted.
  func testFalsey() {
    let template = AnkiTemplate(template: "{{#boolean}}This should not be rendered.{{/boolean}}")
    XCTAssertEqual(try? template.render(["boolean": false]), "")
  }

  func testInvertedTruthySection() {
    let template = AnkiTemplate(template: "{{^boolean}}This should not be rendered.{{/boolean}}")
    XCTAssertEqual(try? template.render(["boolean": true]), "")
  }

  func testInvertedFalseySection() {
    let template = AnkiTemplate(template: "{{^boolean}}This should be rendered.{{/boolean}}")
    XCTAssertEqual(try? template.render(), "This should be rendered.")
  }
}
