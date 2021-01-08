// Copyright © 2019-present Brian Dewey.

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
    XCTAssertEqual(try? template.render(["boolean": 312]), "")
  }

  func testInvertedFalseySection() {
    let template = AnkiTemplate(template: "{{^boolean}}This should be rendered.{{/boolean}}")
    XCTAssertEqual(try? template.render(), "This should be rendered.")
  }

  func testReplaceTag() {
    let template = AnkiTemplate(template: "Hello {{name}}.")
    XCTAssertEqual(try? template.render(["name": "Joe"]), "Hello Joe.")
  }

  func testAnkiAllowsSpaces() {
    let template = AnkiTemplate(template: "Hello {{field 1}}.")
    XCTAssertEqual(try? template.render(["field 1": "Jane"]), "Hello Jane.")
  }
}
