// Copyright © 2019-present Brian Dewey.

import Foundation
import GRDB

public struct Card: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
  public init(id: Int = 0, noteID: Int, deckID: Int, templateIndex: Int, modificationTimeSeconds: Int = 0, queue: Card.CardQueue = CardQueue.new, due: Int = 0, type: Card.CardType = CardType.new, interval: Int = 0, factor: Int = 0, reps: Int = 0, lapses: Int = 0, left: Int = 0) {
    self.id = id
    self.noteID = noteID
    self.deckID = deckID
    self.templateIndex = templateIndex
    self.modificationTimeSeconds = modificationTimeSeconds
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

  public static var databaseTableName: String { "cards" }
  public var id = 0
  public var noteID: Int
  public var deckID: Int
  public var templateIndex: Int
  public var modificationTimeSeconds = 0
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

  // MARK: Unused

  public let usn = 0
  public let odue = 0
  public let odid = 0
  public let flags = 0
  public let data = ""

  enum CodingKeys: String, CodingKey {
    case id
    case noteID = "nid"
    case deckID = "did"
    case templateIndex = "ord"
    case modificationTimeSeconds = "mod"
    case queue
    case due
    case type
    case interval = "ivl"
    case factor
    case reps
    case lapses
    case left
    case usn, odue, odid, flags, data
  }
}
