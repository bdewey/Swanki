// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB

public struct Card: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
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
  public let id: Int
  public let noteID: Int
  public let deckID: Int
  public let templateIndex: Int
  public var queue: CardQueue
  /// Due is used differently for different card types:
  /// - new: note id or random int
  /// - due: integer day, relative to the collection's creation time <-- I'm changing the "relative" bit because that's dumb
  /// - learning: integer timestamp
  public var due: Int
  public var type: CardType
  public var interval: Int
  public var factor: Int
  public var reps: Int
  public var lapses: Int
  public var left: Int

  enum CodingKeys: String, CodingKey {
    case id
    case noteID = "nid"
    case deckID = "did"
    case templateIndex = "ord"
    case queue
    case due
    case type
    case interval = "ivl"
    case factor
    case reps
    case lapses
    case left
  }
}
