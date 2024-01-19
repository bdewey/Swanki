// Copyright © 2019-present Brian Dewey.

import Foundation
import GRDB
import SpacedRepetitionScheduler

/// A study record in the revlog table.
public struct LogEntry: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTableName: String { "revlog" }

  public var id = 0
  public var cardID = 0
  public var usn = 0
  public var ease = RecallEase.easy
  public var interval = 0
  public var lastInterval = 0
  public var factor = 0
  public var timeMilliseconds = 0
  public var type = Card.CardType.new

  enum CodingKeys: String, CodingKey {
    case id
    case cardID = "cid"
    case usn
    case ease
    case interval = "ivl"
    case lastInterval = "lastIvl"
    case factor
    case timeMilliseconds = "time"
    case type
  }
}

public extension LogEntry {
  /// Initializes a log entry recording the state change from an old card to a new card.
  init(now: Date, oldCard: Card, newCard: Card, answer: RecallEase, studyTime: TimeInterval) {
    precondition(oldCard.id == newCard.id)
    self.id = Int(floor(now.timeIntervalSince1970 * 1000)) // millisecond timestamp
    self.cardID = oldCard.id
    self.ease = answer
    self.interval = newCard.interval
    self.lastInterval = oldCard.interval
    self.factor = newCard.factor
    self.timeMilliseconds = Int(floor(studyTime * 1000))
    self.type = newCard.type
  }
}
