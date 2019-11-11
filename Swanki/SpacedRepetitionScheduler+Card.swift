// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Bridges between `Card` and `SpacedRepetitionScheduler`
public extension SpacedRepetitionScheduler {
  /// Creates a `SpacedRepetitionScheduler.Item` corresponding to this Card.
  func makeSchedulingItem(from card: Card) -> Item {
    Item(
      schedulingState: .review,
      reviewCount: card.reps,
      lapseCount: card.lapses,
      interval: (card.interval < 0) ? (TimeInterval(-1 * card.interval)) : TimeInterval(card.interval) * .day,
      factor: Double(card.factor) / 1000
    )
  }
}
