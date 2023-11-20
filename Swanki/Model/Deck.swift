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

  @discardableResult
  public func addNote(_ factory: () -> Note = { Note() }) -> Note {
    let note = factory()
    if let modelContext {
      modelContext.insert(note)
    }
    note.deck = self
    return note
  }
}
