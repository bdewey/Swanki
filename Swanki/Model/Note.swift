// Copyright © 2019-present Brian Dewey.

import AVFoundation
import Foundation
import SwiftData

@Model
/// Cards are derived from Notes by applying templates.
///
/// For example, when studying foreign language vocabulary, the `Note` will contain the vocabulary pair,
/// and from this we can derive two cards, one for each direction of the pair (Spanish from English, Engish from Spanish).
public final class Note {
  public init(deck: Deck? = nil, modificationTime: Date = Date.distantPast, fields: [String: String] = [:]) {
    self.deck = deck
    self.modificationTime = modificationTime
    self.fields = fields
  }

  public var deck: Deck?
  public var modificationTime = Date.distantPast
  public var fields: [String: String] = [:]

  /// A type that identifies a value inside of ``Note/fields``
  public struct Key: RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
      self.rawValue = value
    }
  }

  @Relationship(deleteRule: .cascade, inverse: \Card.note)
  public var cards: [Card]? = []

  @discardableResult
  public func addCard(_ factory: () -> Card) -> Card {
    let card = factory()
    if let modelContext {
      modelContext.insert(card)
    }
    card.deck = deck
    card.note = self
    return card
  }

  @discardableResult
  public func addCard(_ cardType: CardType) -> Card {
    addCard {
      Card(type: cardType)
    }
  }

  public static func forDeck(_ deck: Deck) -> Predicate<Note> {
    let id = deck.id
    return #Predicate<Note> { note in
      note.deck?.id == id
    }
  }

  /// Gets/sets the corresponding value in ``fields``
  public subscript(key: Key) -> String? {
    get {
      fields[key.rawValue]
    }
    set {
      fields[key.rawValue] = newValue
    }
  }
}
