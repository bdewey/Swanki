// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

public extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

public enum SchedulingState: Equatable {
  /// The item is in the learning state.
  /// - parameter step: How many learning steps have been completed. `step == 0` implies a new card.
  case learning(step: Int)

  /// The item is in the "review" state
  case review
}

public protocol SchedulableItem {
  /// Current state of the item.
  var schedulingState: SchedulingState { get }

  /// How many times this item has been reviewed.
  var reviewCount: Int { get }

  /// When this item is due to be reviewed again.
  var due: Date { get }
}

public struct SchedulingResult: SchedulableItem {
  public var schedulingState: SchedulingState
  public var reviewCount: Int
  public var due: Date

  /// Public initializer so we can create these in other modules.
  public init(
    schedulingState: SchedulingState = .learning(step: 0),
    reviewCount: Int = 0,
    due: Date = .distantPast
  ) {
    self.schedulingState = schedulingState
    self.reviewCount = reviewCount
    self.due = due
  }

  /// Casting initializer: Creates a `SchedulingResult` from any `SchedulableItem`
  public init(_ item: SchedulableItem) {
    self.schedulingState = item.schedulingState
    self.reviewCount = item.reviewCount
    self.due = item.due
  }
}

/// A spaced-repetition scheduler that implements an Anki-style algorithm, where items can be in either a "learning" state
/// with a specific number of steps to "graduate", or the items can be in the "review" state with a geometric progression of times
/// between reviews.
public struct SpacedRepetitionScheduler {
  /// Public initializer.
  /// - parameter learningIntervals: The time between successive stages of "learning" a card.
  public init(
    learningIntervals: [TimeInterval],
    easyGraduatingInterval: TimeInterval = 4 * .day,
    goodGraduatingInterval: TimeInterval = 1 * .day
  ) {
    self.learningIntervals = learningIntervals
    self.easyGraduatingInterval = easyGraduatingInterval
    self.goodGraduatingInterval = goodGraduatingInterval
  }

  /// The intervals between successive steps when "learning" an item.
  public let learningIntervals: [TimeInterval]

  /// When a card graduates from "learning" to "review" with an "easy" answer, it's scheduled out by this interval.
  public let easyGraduatingInterval: TimeInterval

  /// When a card graduates from "learning" to "review" with a "good" answer, it's schedule out by this interval.
  public let goodGraduatingInterval: TimeInterval

  /// Determines the next state of a schedulable item for all possible answers.
  /// - parameter item: The item to schedule.
  /// - parameter now: The current time. Item due dates will be relative to this date.
  /// - returns: A mapping of "answer" to "next state of the schedulable item"
  public func scheduleItem(
    _ item: SchedulableItem,
    now: Date = Date()
  ) -> [CardAnswer: SchedulingResult] {
    var results = [CardAnswer: SchedulingResult]()
    for answer in CardAnswer.allCases {
      results[answer] = result(item: item, answer: answer, now: now)
    }
    return results
  }

  /// Computes the scheduling result given an item, answer, and current time.
  private func result(item: SchedulableItem, answer: CardAnswer, now: Date) -> SchedulingResult {
    var result = SchedulingResult(item)
    result.reviewCount += 1
    switch (item.schedulingState, answer) {
    case (.learning, .again):
      // Go back to the initial learning step, schedule out a tiny bit.
      result.schedulingState = .learning(step: 0)
      result.due = now.addingTimeInterval(learningIntervals.first ?? 60)
    case (.learning, .easy):
      // Immediate graduation!
      result.schedulingState = .review
      result.due = now.addingTimeInterval(easyGraduatingInterval)
    case (.learning(let step), .hard):
      // Stay on the same step.
      let interval = learningIntervals[step]
      result.due = now.addingTimeInterval(interval)
    case (.learning(let step), .good):
      // Move to the next step.
      if step >= learningIntervals.count {
        // Graduate to "review"
        result.schedulingState = .review
        result.due = now.addingTimeInterval(goodGraduatingInterval)
      } else {
        let interval = learningIntervals[step]
        result.schedulingState = .learning(step: step + 1)
        result.due = now.addingTimeInterval(interval)
      }
    default:
      // NOTHING
      break
    }
    return result
  }
}
