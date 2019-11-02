// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Walks through cards in a collection
public struct StudySequence {
  /// The database.
  public let collectionDatabase: CollectionDatabase

  /// The specific decks from which to select study cards.
  public let decks: [Int]
}

extension StudySequence: Sequence {
  public struct Iterator: IteratorProtocol {
    /// Designated initializer.
    init(studySequence: StudySequence) {
      do {
        let flattenedCollection = try studySequence.decks.map({ try studySequence.collectionDatabase.fetchNewCards(from: $0) }).joined()
        self.cards = Array(flattenedCollection)
      } catch {
        logger.error("Unexpected error building study sequence: \(error)")
        self.cards = []
      }
      self.currentIndex = 0
    }

    private let cards: [Card]
    private var currentIndex: Int

    public mutating func next() -> Card? {
      if currentIndex >= cards.endIndex {
        return nil
      }
      let result = cards[currentIndex]
      currentIndex += 1
      return result
    }
  }

  public __consuming func makeIterator() -> Iterator {
    return Iterator(studySequence: self)
  }
}
