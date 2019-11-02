// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB

public struct Card: Codable, FetchableRecord, PersistableRecord, Identifiable {
  public enum CardType: Int, Codable {
    case new, learning, due, filtered
  }

  public static var databaseTableName: String { "cards" }
  public let id: Int
  public let noteID: Int
  public let deckID: Int
  public let templateIndex: Int
  public let queue: Int
  public let type: CardType
  public let interval: Int
  public let factor: Int
  public let reps: Int
  public let lapses: Int
  public let left: Int

  enum CodingKeys: String, CodingKey {
    case id
    case noteID = "nid"
    case deckID = "did"
    case templateIndex = "ord"
    case queue
    case type
    case interval = "ivl"
    case factor
    case reps
    case lapses
    case left
  }
}
