// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Holds an observable array of CollectionDatabase objects.
final class Databases: ObservableObject {
  init(_ databases: [CollectionDatabase] = []) {
    self.contents = databases
  }

  @Published var contents: [CollectionDatabase]

  /// All Swanki databases are written in the user document directory.
  private let homeDirectory = try! FileManager.default.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: true
  )

  func scanHomeDirectory() {
    let homeDirectoryContents = (try? FileManager.default.contentsOfDirectory(at: homeDirectory, includingPropertiesForKeys: nil, options: [])) ?? []
    let databaseURLs = homeDirectoryContents.filter { $0.pathExtension == "swanki" }
    let openDatabases = databaseURLs.compactMap { try? openDatabase(at: $0) }
    contents.append(contentsOf: openDatabases)
  }

  func openDatabase(at url: URL, importing importURL: URL? = nil) throws -> CollectionDatabase {
    let database = CollectionDatabase(url: url)
    if let importURL = importURL {
      try database.importPackage(importURL)
    }
    try database.openDatabase()
    try database.fetchMetadata()
    return database
  }

  /// Imports an Anki package (zipped "apkg" file) into a Swanki database.
  func importPackage(at url: URL) {
    let bundleURL = homeDirectory
      .appendingPathComponent(url.lastPathComponent, isDirectory: true)
      .deletingPathExtension()
      .appendingPathExtension("swanki")
    // TODO: Keep appending increasing numbers and avoid clobbering any existing content
    try? FileManager.default.removeItem(at: bundleURL)
    do {
      let database = try openDatabase(at: bundleURL, importing: url)
      contents.append(database)
      logger.info("Imported \(bundleURL)")
    } catch {
      logger.error("Unexpected error importing \(url) to \(bundleURL): \(error)")
    }
  }
}
