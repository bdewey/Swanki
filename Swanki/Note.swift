// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

struct Note: Codable, FetchableRecord, PersistableRecord {
  static var databaseTableName: String { "notes" }
  let id: Int
  let guid: String
  let mid: Int
  let mod: Int
  let usn: Int
  let tags: String
  let flds: String
}
