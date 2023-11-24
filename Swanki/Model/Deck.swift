// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
import SwiftData

@Model
/// A Deck is a collection of cards that can be studied.
public final class Deck {
  public init(name: String) {
    self.name = name
  }

  public var id = UUID()
  public var name: String = "Untitled"

  @Relationship(deleteRule: .cascade, inverse: \Card.deck)
  public var cards: [Card]? = []

  @Relationship(deleteRule: .cascade, inverse: \Note.deck)
  public var notes: [Note]? = []

  @Relationship(deleteRule: .cascade, inverse: \LogEntry.deck)
  public var logEntries: [LogEntry]? = []

  @discardableResult
  public func addNote(_ factory: () -> Note = { Note() }) -> Note {
    let note = factory()
    if let modelContext {
      modelContext.insert(note)
    }
    note.deck = self
    return note
  }

  static func spanishDeck(in modelContext: ModelContext) throws -> Deck {
    let existingDecks = try modelContext.fetch(FetchDescriptor<Deck>(
      predicate: #Predicate { $0.name == "Spanish Lesson 2" }
    ))
    if !existingDecks.isEmpty {
      return existingDecks[0]
    } else {
      let deck = Deck(name: "Spanish Lesson 2")
      modelContext.insert(deck)
      return deck
    }
  }
}
