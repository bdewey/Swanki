// Copyright © 2019 Brian's Brain. All rights reserved.

import Swanki
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  let scheduler = SpacedRepetitionScheduler(
    learningIntervals: [1 * .minute, 10 * .minute]
  )

  func testScheduleNewCard() {
    let newItem = SchedulingResult(schedulingState: .learning(step: 0))
    let now = Date()
    let results = scheduler.scheduleItem(newItem, now: now)
    XCTAssertEqual(results.count, CardAnswer.allCases.count)
    // Check that the repetition count increased for all items.
    for result in results.values {
      XCTAssertEqual(result.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.schedulingState, .learning(step: 1))
    XCTAssertEqual(results[.again]?.due, now.addingTimeInterval(scheduler.learningIntervals.first!))
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.schedulingState, .review)
    XCTAssertEqual(results[.easy]?.due, now.addingTimeInterval(scheduler.easyGraduatingInterval))
    XCTAssertEqual(results[.easy]?.interval, scheduler.easyGraduatingInterval)

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.schedulingState, .learning(step: 1))
    XCTAssertEqual(results[.good]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))
    XCTAssertEqual(results[.good]?.interval, scheduler.learningIntervals[0])

    // Cards that were "hard" stay on the same state.
    XCTAssertEqual(results[.hard]?.schedulingState, .learning(step: 0))
    XCTAssertEqual(results[.hard]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))
    XCTAssertEqual(results[.hard]?.interval, scheduler.learningIntervals[0])
  }

  func testProgressFromNewToReview() {
    var item = SchedulingResult()

    for _ in 0 ... scheduler.learningIntervals.count {
      // Answer the item as "good"
      item = scheduler.scheduleItem(item)[.good]!
    }
    XCTAssertEqual(item.schedulingState, .review)
    XCTAssertEqual(item.interval, scheduler.goodGraduatingInterval)
  }

  func testScheduleReviewCard() {
    let now = Date()
    let reviewItem = SchedulingResult(
      schedulingState: .review,
      reviewCount: 5,
      interval: 4 * .day,
      due: now
    )
    let results = scheduler.scheduleItem(reviewItem, now: now)
    XCTAssertEqual(results[.again]?.lapseCount, 1)
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)
    XCTAssertEqual(results[.again]?.schedulingState, .learning(step: 1))
  }
}
