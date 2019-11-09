// Copyright © 2019 Brian's Brain. All rights reserved.

import Swanki
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  func testScheduleNewCard() {
    let scheduler = SpacedRepetitionScheduler(
      learningIntervals: [1 * .minute, 10 * .minute]
    )
    let newItem = SchedulingResult(schedulingState: .learning(step: 0))
    let now = Date()
    let results = scheduler.scheduleItem(newItem, now: now)
    XCTAssertEqual(results.count, CardAnswer.allCases.count)
    // Check that the repetition count increased for all items.
    for result in results.values {
      XCTAssertEqual(result.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.schedulingState, .learning(step: 0))
    XCTAssertEqual(results[.again]!.due, now.addingTimeInterval(scheduler.learningIntervals.first!))

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.schedulingState, .review)
    XCTAssertEqual(results[.easy]?.due, now.addingTimeInterval(scheduler.easyGraduatingInterval))

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.schedulingState, .learning(step: 1))
    XCTAssertEqual(results[.good]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))

    // Cards that were "hard" stay on the same state.
    XCTAssertEqual(results[.hard]?.schedulingState, .learning(step: 0))
    XCTAssertEqual(results[.hard]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))
  }
}
