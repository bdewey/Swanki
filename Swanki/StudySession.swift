// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Holds a collection of cards from a database to study.
public final class StudySession: ObservableObject {
  public init(collectionDatabase: CollectionDatabase, decks: [Int]) {
    self.collectionDatabase = collectionDatabase
    self.decks = decks

    do {
      let learningCards = try decks.map { try collectionDatabase.fetchLearningCards(from: $0) }.joined()
      logger.info("Found \(learningCards.count) learning card(s) for decks \(decks)")
      self.learningCards = ArraySlice(learningCards)
      let newCards = try decks.map { try collectionDatabase.fetchNewCards(from: $0) }.joined()
      self.newCards = ArraySlice(newCards)
      logger.info("Found \(newCards.count) new card(s) for decks \(decks)")
      let reviewCards = try decks.map { try collectionDatabase.fetchReviewCards(from: $0) }.joined()
      logger.info("Found \(reviewCards.count) review card(s) for decks \(decks)")
      self.reviewCards = ArraySlice(reviewCards)
    } catch {
      logger.error("Unexpected error building study sequence: \(error)")
      self.learningCards = ArraySlice([])
      self.newCards = ArraySlice([])
      self.reviewCards = ArraySlice([])
    }
    advance()
  }

  /// The database.
  public let collectionDatabase: CollectionDatabase

  /// The specific decks from which to select study cards.
  public let decks: [Int]

  @Published public private(set) var learningCards: ArraySlice<Card>
  @Published public private(set) var newCards: ArraySlice<Card>
  @Published public private(set) var reviewCards: ArraySlice<Card>

  @Published public private(set) var currentCard: Card?

  public func advance() {
    currentCard = next()
    logger.debug("Card id is now \(currentCard?.id ?? -1)")
  }

  private func next() -> Card? {
    if let card = learningCards.popFirst() {
      return card
    }
    if let card = newCards.popFirst() {
      return card
    }
    if let card = reviewCards.popFirst() {
      return card
    }
    return nil
  }
}
