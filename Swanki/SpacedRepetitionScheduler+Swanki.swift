//
//  SpacedRepetitionScheduler+Swanki.swift
//  Swanki
//
//  Created by Brian Dewey on 11/16/23.
//  Copyright © 2023 Brian's Brain. All rights reserved.
//

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
      return .learning(step: learningStep)
    } else {
      return .review
    }
  }

  func applySchedulingItem(_ item: SpacedRepetitionScheduler.Item) {
    switch item.learningState {
    case .learning(step: let step):
      learningStep = step
    case .review:
      learningStep = nil
    }
    reps = item.reviewCount
    lapses = item.lapseCount
    interval = item.interval
    factor = item.factor
  }
}
