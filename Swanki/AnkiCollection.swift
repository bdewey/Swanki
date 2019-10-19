// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

struct AnkiCollection: Codable, FetchableRecord, PersistableRecord {
  static var databaseTableName: String { "col" }
  let id: Int
  let models: String

  func loadModels() throws -> [NoteModel] {
    let decoder = JSONDecoder()
    let data = models.data(using: .utf8)!
    let dict = try decoder.decode([String: NoteModel].self, from: data)
    return Array(dict.values)
  }
}

struct NoteModel {
  let id: Int
  let css: String
  let deckID: Int
  let fields: [NoteField]
  let modelType: ModelType

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

  init(from decoder: Decoder) throws {
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

enum ModelType: Int, Codable {
  case standard = 0
  case cloze = 1
}

struct NoteField: Codable {
  let font: String
  let name: String
  let ord: Int
}
