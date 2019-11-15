// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

public extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

public extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    if self > range.upperBound {
      return range.upperBound
    } else if self < range.lowerBound {
      return range.lowerBound
    } else {
      return self
    }
  }
}

extension Array where Element == (key: CardAnswer, value: SpacedRepetitionScheduler.Item) {
  /// A convenience for searching through a (small) array of keys / values
  public subscript(_ answer: CardAnswer) -> SpacedRepetitionScheduler.Item? {
    for (candidateAnswer, item) in self {
      if candidateAnswer == answer { return item }
    }
    return nil
  }
}

/// A spaced-repetition scheduler that implements an Anki-style algorithm, where items can be in either a "learning" state
/// with a specific number of steps to "graduate", or the items can be in the "review" state with a geometric progression of times
/// between reviews.
public struct SpacedRepetitionScheduler {
  /// The scheduler works with this abstract "item". Since the scheduler needs to create new Items, this is a struct and not a protocol.
  /// The consumer of the scheduler will need to create Items representing whatever is being scheduled, and then map new item state
  /// back to the actual scheduled entity.
  public struct Item {
    public enum LearningState: Equatable {
      /// The item is in the learning state.
      /// - parameter step: How many learning steps have been completed. `step == 0` implies a new card.
      case learning(step: Int)

      /// The item is in the "review" state
      case review
    }

    /// The learning state of this item.
    public var learningState: LearningState

    /// How many times this item has been reviewed.
    public var reviewCount: Int

    /// How many times this item regressed from "review" back to "learning"
    public var lapseCount: Int

    /// The ideal amount of time until seeing this item again.
    public var interval: TimeInterval

    // TODO: This needs a reasonable description
    public var factor: Double

    /// Public initializer so we can create these in other modules.
    public init(
      learningState: LearningState = .learning(step: 0),
      reviewCount: Int = 0,
      lapseCount: Int = 0,
      interval: TimeInterval = 0,
      factor: Double = 2.5
    ) {
      self.learningState = learningState
      self.reviewCount = reviewCount
      self.lapseCount = lapseCount
      self.factor = factor
      self.interval = interval
    }
  }

  /// Public initializer.
  /// - parameter learningIntervals: The time between successive stages of "learning" a card.
  public init(
    learningIntervals: [TimeInterval],
    easyGraduatingInterval: TimeInterval = 4 * .day,
    goodGraduatingInterval: TimeInterval = 1 * .day,
    easyBoost: Double = 1.3
  ) {
    self.learningIntervals = learningIntervals
    self.easyGraduatingInterval = easyGraduatingInterval
    self.goodGraduatingInterval = goodGraduatingInterval
    self.easyBoost = easyBoost
  }

  /// The intervals between successive steps when "learning" an item.
  public let learningIntervals: [TimeInterval]

  /// When a card graduates from "learning" to "review" with an "easy" answer, it's scheduled out by this interval.
  public let easyGraduatingInterval: TimeInterval

  /// When a card graduates from "learning" to "review" with a "good" answer, it's schedule out by this interval.
  public let goodGraduatingInterval: TimeInterval

  /// An additional boost given to "easy" cards in review mode.
  public let easyBoost: Double

  /// Determines the next state of a schedulable item for all possible answers.
  /// - parameter item: The item to schedule.
  /// - parameter now: The current time. Item due dates will be relative to this date.
  /// - returns: An array containing all possible answers and the next state of the item if the person picks that answer.
  public func scheduleItem(
    _ item: Item,
    afterDelay delay: TimeInterval = 0
  ) -> [(key: CardAnswer, value: Item)] {
    return CardAnswer.allCases.map { answer in
      return (answer, result(item: item, answer: answer, delay: delay))
    }
  }

  /// Computes the scheduling result given an item, answer, and current time.
  private func result(item: Item, answer: CardAnswer, delay: TimeInterval) -> Item {
    var result = item
    result.reviewCount += 1
    switch (item.learningState, answer) {
    case (.learning, .again):
      moveToFirstStep(&result)
    case (.learning, .easy):
      // Immediate graduation!
      result.learningState = .review
      result.interval = easyGraduatingInterval
    case (.learning(let step), .hard):
      // Stay on the same step.
      result.interval = learningIntervals[max(0, step-1)]
    case (.learning(let step), .good):
      // Move to the next step.
      if step >= learningIntervals.count {
        // Graduate to "review"
        result.learningState = .review
        result.interval = goodGraduatingInterval
      } else {
        result.interval = learningIntervals[step]
        result.learningState = .learning(step: step + 1)
      }
    case (.review, .again):
      result.lapseCount += 1
      result.factor = max(1.3, result.factor - 0.2)
      moveToFirstStep(&result)
    case (.review, .hard):
      result.interval = result.interval * 1.2
      result.factor = max(1.3, result.factor - 0.15)
    case (.review, .good):
      // Expand interval by factor, fuzzing the result, and ensuring that it at least moves forward
      // by the "hard" amount.
      result.interval = (result.interval + delay / 2) * result.factor
    case (.review, .easy):
      result.interval = (result.interval + delay) * result.factor * easyBoost
      result.factor += 0.15
    }
    return result
  }

  private func moveToFirstStep(_ result: inout Item) {
    // Go back to the initial learning step, schedule out a tiny bit.
    result.learningState = .learning(step: 1)
    result.interval = learningIntervals.first ?? .minute
  }
}

