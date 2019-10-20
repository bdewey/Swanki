// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

public struct CollectionMetadata: Codable, FetchableRecord, PersistableRecord {
  public static var databaseTableName: String { "col" }
  public let id: Int
  public let models: String
  public let dconf: String

  public func loadModels() throws -> [NoteModel] {
    let decoder = JSONDecoder()
    let data = models.data(using: .utf8)!
    let dict = try decoder.decode([String: NoteModel].self, from: data)
    return Array(dict.values)
  }

  public func loadDeckConfigs() throws -> [Int: DeckConfig] {
    let data = dconf.data(using: .utf8)!
    return try JSONDecoder().decode([Int: DeckConfig].self, from: data)
  }
}

public struct NoteModel {
  public let id: Int
  public let css: String
  public let deckID: Int
  public let fields: [NoteField]
  public let modelType: ModelType

  enum CodingKeys: String, CodingKey {
    case id
    case css
    case deckID = "did"
    case fields = "flds"
    case modelType = "type"
  }
}

extension NoteModel: Codable {
  enum NoteDecodingError: Error {
    case noId
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    // Anki sometimes stores id as a string, sometimes as an int. why?
    if let id = try? values.decode(Int.self, forKey: .id) {
      self.id = id
    } else {
      let idString = try values.decode(String.self, forKey: .id)
      if let id = Int(idString) {
        self.id = id
      } else {
        throw NoteDecodingError.noId
      }
    }
    self.css = try values.decode(String.self, forKey: .css)
    self.deckID = try values.decode(Int.self, forKey: .deckID)
    self.fields = try values.decode([NoteField].self, forKey: .fields)
    self.modelType = try values.decode(ModelType.self, forKey: .modelType)
  }
}

public enum ModelType: Int, Codable {
  case standard = 0
  case cloze = 1
}

public struct NoteField: Codable {
  public let font: String
  public let name: String
  public let ord: Int
}
