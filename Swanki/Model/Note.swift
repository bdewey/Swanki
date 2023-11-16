// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

@Model
/// Cards are derived from Notes by applying templates.
///
/// For example, when studying foreign language vocabulary, the `Note` will contain the vocabulary pair,
/// and from this we can derive two cards, one for each direction of the pair (Spanish from English, Engish from Spanish).
public final class Note {
  public init(deck: Deck, modificationTime: Date = Date.distantPast, fields: [String] = []) {
    self.deck = deck
    self.modificationTime = modificationTime
    self.fields = fields
  }

  public var deck: Deck?
  public var modificationTime = Date.distantPast
  public var fields: [String] = []
}
