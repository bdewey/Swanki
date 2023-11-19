// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

@Model
/// A Card is an individual fact to study.
public final class Card {
  public init(
    deck: Deck,
    note: Note,
    type: CardType,
    modificationTime: Date = .distantPast,
    learningStep: Int? = 0,
    due: Date? = nil,
    interval: TimeInterval = 0,
    factor: Double = 0,
    reps: Int = 0,
    lapses: Int = 0,
    left: Int = 0
  ) {
    self.deck = deck
    self.note = note
    self.type = type
    self.modificationTime = modificationTime
    self.learningStep = learningStep
    self.due = due
    self.interval = interval
    self.factor = factor
    self.reps = reps
    self.lapses = lapses
    self.left = left
  }

  public var deck: Deck?
  public var note: Note?
  public var type: CardType
  public var modificationTime = Date.distantPast
  public var learningStep: Int?

  /// Due is used differently for different card types:
  /// - new: note id or random int
  /// - due: integer day, relative to the collection's creation time <-- I'm changing the "relative" bit because that's dumb
  /// - learning: integer timestamp
  public var due: Date?
  public var interval: TimeInterval = 0
  public var factor: Double = 0
  public var reps = 0
  public var lapses = 0
  public var left = 0
}
