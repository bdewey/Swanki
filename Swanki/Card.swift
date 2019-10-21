// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB

public struct Card: Codable, FetchableRecord, PersistableRecord, Identifiable {
  public static var databaseTableName: String { "cards" }
  public let id: Int
  public let noteID: Int
  public let deckID: Int
  public let templateIndex: Int

  enum CodingKeys: String, CodingKey {
    case id
    case noteID = "nid"
    case deckID = "did"
    case templateIndex = "ord"
  }
}
