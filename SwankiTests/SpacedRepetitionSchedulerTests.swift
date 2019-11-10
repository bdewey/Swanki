// Copyright © 2019 Brian's Brain. All rights reserved.

import Swanki
import XCTest

final class SpacedRepetitionSchedulerTests: XCTestCase {
  let scheduler = SpacedRepetitionScheduler(
    learningIntervals: [1 * .minute, 10 * .minute]
  )

  func testScheduleNewCard() {
    let newItem = SpacedRepetitionScheduler.Item(schedulingState: .learning(step: 0))
    let now = Date()
    let results = scheduler.scheduleItem(newItem, now: now)
    XCTAssertEqual(results.count, CardAnswer.allCases.count)
    // Check that the repetition count increased for all items.
    for result in results.values {
      XCTAssertEqual(result.reviewCount, 1)
    }

    XCTAssertEqual(results[.again]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.again]?.due, now.addingTimeInterval(scheduler.learningIntervals.first!))
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)

    // Cards that were "easy" immediately leave the learning state.
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]?.due, now.addingTimeInterval(scheduler.easyGraduatingInterval))
    XCTAssertEqual(results[.easy]?.interval, scheduler.easyGraduatingInterval)

    // Cards that were "good" move to the next state.
    XCTAssertEqual(results[.good]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.good]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))
    XCTAssertEqual(results[.good]?.interval, scheduler.learningIntervals[0])

    // Cards that were "hard" stay on the same state.
    XCTAssertEqual(results[.hard]?.learningState, .learning(step: 0))
    XCTAssertEqual(results[.hard]?.due, now.addingTimeInterval(scheduler.learningIntervals[0]))
    XCTAssertEqual(results[.hard]?.interval, scheduler.learningIntervals[0])
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
    let now = Date()
    let reviewItem = SpacedRepetitionScheduler.Item(
      schedulingState: .review,
      reviewCount: 5,
      interval: 4 * .day,
      due: now
    )
    let results = scheduler.scheduleItem(reviewItem, now: now)
    XCTAssertEqual(results[.again]?.lapseCount, 1)
    XCTAssertEqual(results[.again]?.interval, scheduler.learningIntervals.first)
    XCTAssertEqual(results[.again]?.learningState, .learning(step: 1))
    XCTAssertEqual(results[.again]!.factor, 2.3, accuracy: 0.01)

    XCTAssertEqual(results[.hard]?.lapseCount, 0)
    XCTAssertEqual(results[.hard]?.learningState, .review)
    XCTAssertEqual(results[.hard]!.factor, 2.5 - 0.15, accuracy: 0.01)

    XCTAssertEqual(results[.good]?.lapseCount, 0)
    XCTAssertEqual(results[.good]?.learningState, .review)
    XCTAssertEqual(results[.good]!.factor, 2.5, accuracy: 0.01)

    XCTAssertEqual(results[.easy]?.lapseCount, 0)
    XCTAssertEqual(results[.easy]?.learningState, .review)
    XCTAssertEqual(results[.easy]!.factor, 2.5 + 0.15, accuracy: 0.01)
  }

  func testScheduleReviewHard() {
    let now = Date()
    let reviewItem = SpacedRepetitionScheduler.Item(
      schedulingState: .review,
      reviewCount: 5,
      interval: 4 * .day,
      due: now
    )
    let range = intervalRange(for: reviewItem, now: now, answer: .hard)
    // Upper bound is (hard_interval * current_interval) + fuzz
    XCTAssertEqual(range.upperBound, reviewItem.interval * 1.2 + 1.2 * .day, accuracy: 0.02 * .day)
    // Lower bound gets clamped to current_interval
    XCTAssertEqual(range.lowerBound, reviewItem.interval, accuracy: 0.01)
  }

  func testScheduleReviewGoodNoDelay() {
    let now = Date()
    let reviewItem = SpacedRepetitionScheduler.Item(
      schedulingState: .review,
      reviewCount: 5,
      interval: 14 * .day,
      due: now
    )
    let range = intervalRange(for: reviewItem, now: now, answer: .good, iterations: 5000)
    // Upper bound is (hard_interval * current_interval) + fuzz
    XCTAssertEqual(range.upperBound, reviewItem.interval * reviewItem.factor + 4 * .day, accuracy: 0.02 * .day)
    // Lower bound gets clamped to current_interval * 1.2
    XCTAssertEqual(range.lowerBound, reviewItem.interval * reviewItem.factor - 4 * .day, accuracy: 0.02 * .day)
  }

  func testScheduleReviewGoodWithDelay() {
    let now = Date()
    let reviewItem = SpacedRepetitionScheduler.Item(
      schedulingState: .review,
      reviewCount: 5,
      interval: 14 * .day,
      due: now
    )
    let delay: TimeInterval = 3 * .day
    let range = intervalRange(for: reviewItem, now: now.addingTimeInterval(delay), answer: .good, iterations: 5000)
    // Upper bound is (hard_interval * current_interval) + fuzz
    XCTAssertEqual(range.upperBound, (reviewItem.interval + delay / 2) * reviewItem.factor + 4 * .day, accuracy: 0.02 * .day)
    // Lower bound gets clamped to current_interval * 1.2
    XCTAssertEqual(range.lowerBound, (reviewItem.interval + delay / 2) * reviewItem.factor - 4 * .day, accuracy: 0.02 * .day)
  }

  func testScheduleReviewEasyWithDelay() {
    let now = Date()
    let reviewItem = SpacedRepetitionScheduler.Item(
      schedulingState: .review,
      reviewCount: 5,
      interval: 14 * .day,
      due: now
    )
    let delay: TimeInterval = 3 * .day
    let range = intervalRange(for: reviewItem, now: now.addingTimeInterval(delay), answer: .easy, iterations: 5000)
    // Upper bound is (hard_interval * current_interval) + fuzz
    XCTAssertEqual(range.upperBound, (reviewItem.interval + delay) * reviewItem.factor * scheduler.easyBoost + 4 * .day, accuracy: 0.02 * .day)
    // Lower bound gets clamped to current_interval * 1.2
    XCTAssertEqual(range.lowerBound, (reviewItem.interval + delay) * reviewItem.factor * scheduler.easyBoost - 4 * .day, accuracy: 0.02 * .day)
  }

  func intervalRange(
    for item: SpacedRepetitionScheduler.Item,
    now: Date,
    answer: CardAnswer,
    iterations: Int = 1000
  ) -> ClosedRange<TimeInterval> {
    var maxInterval: TimeInterval = 0
    var minInterval = TimeInterval.greatestFiniteMagnitude
    for _ in 0 ..< iterations {
      let result = scheduler.scheduleItem(item, now: now)[answer]!
      maxInterval = max(maxInterval, result.interval)
      minInterval = min(minInterval, result.interval)
    }
    return minInterval ... maxInterval
  }
}
