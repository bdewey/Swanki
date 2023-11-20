// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
import SpacedRepetitionScheduler
import SwiftData

@MainActor
public final class NewStudySession {
  public enum Error: Swift.Error {
    case noCard
  }

  public init(modelContext: ModelContext, newCardLimit: Int) {
    self.modelContext = modelContext
    self.newCardLimit = newCardLimit
  }

  public let modelContext: ModelContext
  public let newCardLimit: Int

  public private(set) var cards: ArraySlice<Card> = []
  public private(set) var newCardCount = 0
  public private(set) var learningCardCount = 0

  public func loadCards(dueBefore dueDate: Date) throws {
    let newCardsLearnedToday = try modelContext.fetchCount(FetchDescriptor(predicate: LogEntry.newCardsLearned(on: dueDate)))
    if newCardsLearnedToday < newCardLimit {
      let newCards = try modelContext.fetch(FetchDescriptor(predicate: Card.newCards)).prefix(newCardLimit - newCardsLearnedToday)
      newCardCount = newCards.count
      cards = newCards
    } else {
      newCardCount = 0
      cards = []
    }
    let learningCards = try modelContext.fetch(FetchDescriptor(predicate: Card.cardsDue(before: dueDate)))
    learningCardCount = learningCards.count
    logger.debug("Looking for cards due before \(ISO8601DateFormatter().string(from: dueDate)): Found \(self.newCardCount) new, \(self.learningCardCount) learning")
    cards += learningCards
  }

  public func updateCurrentCardSchedule(
    answer: CardAnswer,
    schedulingItem: SpacedRepetitionScheduler.Item,
    studyTime: TimeInterval,
    currentDate: Date
  ) throws {
    guard let card = cards.popFirst() else {
      throw Error.noCard
    }
    // The new entry needs to be added to the model context before we can create the relationship to `card`
    let entry = LogEntry(timestamp: currentDate, answer: answer, oldReps: card.reps, studyTime: studyTime)
    modelContext.insert(entry)
    entry.card = card
    card.applySchedulingItem(schedulingItem, currentDate: currentDate)
    logger.debug("Finished scheduling card \(card.id), due \(card.due.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "nil")")
    try loadCards(dueBefore: .now)
  }
}
