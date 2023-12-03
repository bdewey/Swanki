// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

public extension ModelContext {
  func summaryStatistics(on day: Date = .now, deck: Deck? = nil) throws -> SummaryStatistics {
    var stats = SummaryStatistics()
    let cards = try fetch(FetchDescriptor(predicate: Card.allCards(deck: deck)))
    for card in cards {
      if card.reps == 0 {
        stats.newCardCount += 1
      } else if card.interval >= .day {
        stats.masteredCardCount += 1
        stats.xp += 1
      } else {
        stats.learningCardCount += 1
        stats.xp += 1
      }
      if (card.due ?? .distantPast) >= day {
        stats.xp += Int(floor(card.interval / .day))
      }
    }
    return stats
  }
}
