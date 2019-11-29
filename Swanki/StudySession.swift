// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Holds a collection of cards from a database to study.
public final class StudySession: ObservableObject {
  public init(collectionDatabase: CollectionDatabase, deckModel: DeckModel) {
    self.collectionDatabase = collectionDatabase
    self.deckModel = deckModel

    do {
      var learningCardCount = 0
      var newCardCount = 0
      var cards: [Card] = []
      let learningCards = try collectionDatabase.fetchLearningCards(from: deckModel.id)
      logger.info("Found \(learningCards.count) learning card(s) for decks \(deckModel.id)")
      learningCardCount += learningCards.count
      cards.append(contentsOf: learningCards)
      let newCards = try collectionDatabase.fetchNewCards(from: deckModel.id)
      cards.append(contentsOf: newCards)
      newCardCount += newCards.count
      logger.info("Found \(newCards.count) new card(s) for decks \(deckModel.id)")
      let reviewCards = try collectionDatabase.fetchReviewCards(from: deckModel.id)
      logger.info("Found \(reviewCards.count) review card(s) for decks \(deckModel.id)")
      cards.append(contentsOf: reviewCards)
      learningCardCount += reviewCards.count
      self.learningCardCount = learningCardCount
      self.newCardCount = newCardCount
      self.cards = ArraySlice(cards)
    } catch {
      logger.error("Unexpected error building study sequence: \(error)")
      self.cards = ArraySlice([])
      self.learningCardCount = 0
      self.newCardCount = 0
    }
    assert(learningCardCount + newCardCount == cards.count)
  }

  /// The database.
  public let collectionDatabase: CollectionDatabase

  /// The specific decks from which to select study cards.
  public let deckModel: DeckModel

  @Published public private(set) var learningCardCount: Int
  @Published public private(set) var newCardCount: Int

  @Published public private(set) var cards: ArraySlice<Card>

  public func recordAnswer(_ answer: CardAnswer, studyTime: TimeInterval) throws {
    guard let currentCard = cards.popFirst() else {
      return
    }
    switch currentCard.queue {
    case .new:
      newCardCount -= 1
    default:
      learningCardCount -= 1
    }
    try collectionDatabase.recordAnswer(answer, for: currentCard, studyTime: studyTime)
  }
}
