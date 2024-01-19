// Copyright © 2019-present Brian Dewey.

import Foundation
import SpacedRepetitionScheduler

extension SchedulingParameters {
  static let builtin = SchedulingParameters(learningIntervals: [.minute, 10 * .minute])
}

extension PromptSchedulingMetadata {
  init(_ card: Card) {
    self.init(
      mode: card.learningState,
      reviewCount: card.reps,
      lapseCount: card.lapses,
      interval: card.interval,
      reviewSpacingFactor: card.factor == 0 ? 2.5 : card.factor
    )
  }
}

extension Card {
  var learningState: PromptSchedulingMode {
    if let learningStep {
      .learning(step: learningStep)
    } else {
      .review
    }
  }

  func applySchedulingItem(_ item: PromptSchedulingMetadata, currentDate: Date) {
    switch item.mode {
    case .learning(step: let step):
      learningStep = step
    case .review:
      learningStep = nil
    }
    reps = item.reviewCount
    lapses = item.lapseCount
    interval = item.interval
    due = currentDate.addingTimeInterval(item.interval)
    factor = item.reviewSpacingFactor
  }
}
