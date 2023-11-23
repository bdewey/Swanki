// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
import SpacedRepetitionScheduler
import SwiftData

@MainActor
@Observable
/// A sequence of cards to study.
public final class StudySession {
  public enum Error: Swift.Error {
    case noCard
  }

  /// Designated initializer.
  /// - Parameters:
  ///   - modelContext: The model context to query for ``Card`` models.
  ///   - deck: An optional ``Deck`` to confine the ``Card`` search.
  ///   - newCardLimit: The maximum number of new cards to learn per day.
  public init(modelContext: ModelContext, deck: Deck? = nil, newCardLimit: Int) {
    self.modelContext = modelContext
    self.deck = deck
    self.newCardLimit = newCardLimit
  }

  /// The model context to query for ``Card`` models.
  public let modelContext: ModelContext

  /// An optional ``Deck`` to confine the ``Card`` search.
  public let deck: Deck?

  /// The maximum number of new cards to learn per day.
  public let newCardLimit: Int

  /// The current card to study. If nil, studying for the day is done.
  public private(set) var currentCard: Card?

  /// The count of new cards available to study.
  public private(set) var newCardCount = 0

  /// The count of cards to review.
  public private(set) var learningCardCount = 0

  /// Loads cards for the study session.
  public func loadCards(dueBefore dueDate: Date) throws {
    let previousCardID = currentCard?.id.description
    currentCard = nil
    let newCardsLearnedToday = try modelContext.fetchCount(FetchDescriptor(predicate: LogEntry.newCardsLearned(on: dueDate)))
    if newCardsLearnedToday < newCardLimit {
      let newCards = try modelContext.fetch(FetchDescriptor(predicate: Card.newCards(deck: deck))).prefix(newCardLimit - newCardsLearnedToday)
      newCardCount = newCards.count
      currentCard = newCards.first
    } else {
      newCardCount = 0
    }
    let learningCards = try modelContext.fetch(FetchDescriptor(predicate: Card.cardsDue(before: dueDate, deck: deck)))
    learningCardCount = learningCards.count
    logger.debug("Looking for cards due before \(ISO8601DateFormatter().string(from: dueDate)): Found \(self.newCardCount) new, \(self.learningCardCount) learning")
    currentCard = currentCard ?? learningCards.first
    let currentCardID = currentCard?.id.description
    logger.debug("Current card was \(previousCardID ?? "nil"), is now \(currentCardID ?? "nil")")
  }

  /// Updates ``currentCard`` with the learner's answer.
  /// - Parameters:
  ///   - answer: The answer that the learner selected.
  ///   - schedulingItem: The updated scheduling information for this card.
  ///   - studyTime: How long the learner took to select the answer.
  ///   - currentDate: The current time.
  public func updateCurrentCardSchedule(
    answer: CardAnswer,
    schedulingItem: SpacedRepetitionScheduler.Item,
    studyTime: TimeInterval,
    currentDate: Date = .now
  ) throws {
    guard let card = currentCard else {
      throw Error.noCard
    }
    // The new entry needs to be added to the model context before we can create the relationship to `card`
    let entry = LogEntry(timestamp: currentDate, answer: answer, oldReps: card.reps, studyTime: studyTime)
    modelContext.insert(entry)
    entry.card = card
    card.applySchedulingItem(schedulingItem, currentDate: currentDate)
    logger.debug("Finished scheduling card \(card.id) studyTime \(studyTime), due \(card.due.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "nil")")
    try loadCards(dueBefore: .now)
  }
}
