// Copyright © 2019-present Brian Dewey.

import Foundation
import SpacedRepetitionScheduler

extension SpacedRepetitionScheduler {
  static let builtin = SpacedRepetitionScheduler(learningIntervals: [.minute, 10 * .minute])
}

extension SpacedRepetitionScheduler.Item {
  init(_ card: Card) {
    self.init(
      learningState: card.learningState,
      reviewCount: card.reps,
      lapseCount: card.lapses,
      interval: card.interval,
      factor: card.factor
    )
  }
}

extension Card {
  var learningState: SpacedRepetitionScheduler.Item.LearningState {
    if let learningStep {
      .learning(step: learningStep)
    } else {
      .review
    }
  }

  func applySchedulingItem(_ item: SpacedRepetitionScheduler.Item, currentDate: Date) {
    switch item.learningState {
    case .learning(step: let step):
      learningStep = step
    case .review:
      learningStep = nil
    }
    reps = item.reviewCount
    lapses = item.lapseCount
    interval = item.interval
    due = currentDate.addingTimeInterval(item.interval)
    factor = item.factor
  }
}
