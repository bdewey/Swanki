// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Bridges between `Card` and `SpacedRepetitionScheduler`
public extension SpacedRepetitionScheduler {
  init(config: DeckConfig) {
    self.init(
      learningIntervals: config.new.delays.map { Double($0) * .minute },
      easyGraduatingInterval: TimeInterval(config.new.ints[1]) * .day,
      goodGraduatingInterval: TimeInterval(config.new.ints[0]) * .day,
      easyBoost: config.rev.ease4
    )
  }

  /// Creates a `SpacedRepetitionScheduler.Item` corresponding to this Card.
  func makeSchedulingItem(for card: Card) -> Item {
    Item(
      learningState: learningState(for: card),
      reviewCount: card.reps,
      lapseCount: card.lapses,
      interval: (card.interval < 0) ? TimeInterval(-1 * card.interval) : TimeInterval(card.interval) * .day,
      factor: Double(card.factor) / 1000
    )
  }

  func learningState(for card: Card) -> Item.LearningState {
    switch card.queue {
    case .new:
      return .learning(step: 0)
    case .learning, .futureLearning:
      return .learning(step: max(0, learningIntervals.count - card.left))
    case .due:
      return .review
    default:
      preconditionFailure("Trying to schedule an unschedulable card")
    }
  }

  func applyItem(_ item: Item, to card: inout Card, now: Date = Date()) {
    switch item.learningState {
    case .learning(step: let step):
      card.queue = .learning
      card.left = learningIntervals.count - step
      // Store an integer number of seconds since the reference date. Don't fuzz.
      // TODO: I'm not using the "we're still learning this card but not today" state that Anki does.
      //       Do I have to?
      card.due = now.addingTimeInterval(item.interval).secondsRelativeFormat
    case .review:
      card.queue = .due
      card.left = 0
      // Store an integer number of dates since the reference date.
      card.due = now.addingTimeInterval(item.interval.fuzzed()).dayRelativeFormat
    }
    card.reps = item.reviewCount
    card.lapses = item.lapseCount
    card.interval = (item.interval < .day) ? (-1 * Int(round(item.interval))) : Int(round(item.interval / .day))
    card.factor = Int(round(item.factor * 1000))
  }
}
