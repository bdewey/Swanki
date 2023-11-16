// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

@Model
/// A Card is an individual fact to study.
public final class Card {
  public init(
    deck: Deck,
    modificationTime: Date = .distantPast,
    queue: Card.CardQueue = CardQueue.new,
    due: Int = 0,
    type: Card.CardType = CardType.new,
    interval: Int = 0,
    factor: Int = 0,
    reps: Int = 0,
    lapses: Int = 0,
    left: Int = 0
  ) {
    self.deck = deck
    self.modificationTime = modificationTime
    self.queue = queue
    self.due = due
    self.type = type
    self.interval = interval
    self.factor = factor
    self.reps = reps
    self.lapses = lapses
    self.left = left
  }

  public enum CardType: Int, Codable {
    case new, learning, due, filtered
  }

  public enum CardQueue: Int, Codable {
    case scheduledBuried = -3
    case userBuried = -2
    case suspended = -1
    case new = 0
    case learning = 1
    case due = 2
    case futureLearning = 3
  }

  public var deck: Deck?
  public var modificationTime = Date.distantPast
  public var queue = CardQueue.new

  /// Due is used differently for different card types:
  /// - new: note id or random int
  /// - due: integer day, relative to the collection's creation time <-- I'm changing the "relative" bit because that's dumb
  /// - learning: integer timestamp
  public var due = 0
  public var type = CardType.new
  public var interval = 0
  public var factor = 0
  public var reps = 0
  public var lapses = 0
  public var left = 0
}
