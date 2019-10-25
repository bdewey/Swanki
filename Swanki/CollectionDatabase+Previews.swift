// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

extension CollectionDatabase {
  /// A database that can be used for SwiftUI previews. Created fresh every time the app runs.
  static let testDatabase: CollectionDatabase = {
    let containerURL = FileManager.default.temporaryDirectory.appendingPathComponent("testDatabase")
    let collectionDatabase = CollectionDatabase(url: containerURL)
    do {
      try collectionDatabase.emptyContainer()
      if let url = Bundle.main.url(forResource: "AncientHistory", withExtension: "apkg", subdirectory: "SampleData") {
        try collectionDatabase.importPackage(url)
      }
      try collectionDatabase.openDatabase()
      try collectionDatabase.fetchMetadata()
      try collectionDatabase.fetchNotes()
      return collectionDatabase
    } catch {
      fatalError("Could not make database: \(error)")
    }
  }()
}
