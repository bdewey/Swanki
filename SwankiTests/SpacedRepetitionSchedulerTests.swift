// Copyright © 2019 Brian's Brain. All rights reserved.

import Swanki
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  let scheduler = SpacedRepetitionScheduler(
    learningIntervals: [1 * .minute, 10 * .minute]
  )

  func testScheduleNewCard() {
    let newItem = SpacedRepetitionScheduler.Item(learningState: .learning(step: 0))
    let results = scheduler.scheduleItem(newItem)

    // shouldn't be a "hard" answer
    XCTAssertEqual(results.count, CardAnswer.allCases.count - 1)
    // Check that the repetition count increased for all items.
    for result in results {
      XCTAssertEqual(result.value.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]?.interval, scheduler.easyGraduatingInterval)

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.good]?.interval, scheduler.learningIntervals[0])
  }

  func testProgressFromNewToReview() {
    var item = SpacedRepetitionScheduler.Item()

    for _ in 0 ... scheduler.learningIntervals.count {
      // Answer the item as "good"
      item = scheduler.scheduleItem(item)[.good]!
    }
    XCTAssertEqual(item.learningState, .review)
    XCTAssertEqual(item.interval, scheduler.goodGraduatingInterval)
  }

  func testScheduleReviewCard() {
    let reviewItem = SpacedRepetitionScheduler.Item(
      learningState: .review,
      reviewCount: 5,
      interval: 4 * .day
    )
    let delay: TimeInterval = .day
    let results = scheduler.scheduleItem(reviewItem, afterDelay: delay)
    XCTAssertEqual(results[.again]?.lapseCount, 1)
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)
    XCTAssertEqual(results[.again]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.again]!.factor, 2.3, accuracy: 0.01)

    XCTAssertEqual(results[.hard]?.lapseCount, 0)
    XCTAssertEqual(results[.hard]?.learningState, .review)
    XCTAssertEqual(results[.hard]!.factor, 2.5 - 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.hard]!.interval, reviewItem.interval * 1.2, accuracy: 0.01)

    XCTAssertEqual(results[.good]?.lapseCount, 0)
    XCTAssertEqual(results[.good]?.learningState, .review)
    XCTAssertEqual(results[.good]!.factor, 2.5, accuracy: 0.01)
    XCTAssertEqual(results[.good]!.interval, (reviewItem.interval + delay / 2) * reviewItem.factor, accuracy: 0.01)

    XCTAssertEqual(results[.easy]?.lapseCount, 0)
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]!.factor, 2.5 + 0.15, accuracy: 0.01)
    XCTAssertEqual(results[.easy]!.interval, (reviewItem.interval + delay) * reviewItem.factor * scheduler.easyBoost, accuracy: 0.01)
  }
}
