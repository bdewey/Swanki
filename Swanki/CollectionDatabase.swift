// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB
import Logging
import Zipper

private let logger: Logger = {
  var logger = Logger(label: "org.brians-brain.Swanki.CollectionDatabase")
  logger.logLevel = .debug
  return logger
}()

/// Holds the database containing the Anki collection.
public final class CollectionDatabase: ObservableObject {
  enum Error: Swift.Error {
    case noDatabaseInPackage
    case couldNotLoadPackage
  }

  /// Designated initializer.
  /// - parameter url: The container URL for the main database and all associated media.
  public init(url: URL) {
    self.url = url
  }

  /// The URL that holds the main database and all associated media
  public let url: URL

  /// Queue for performing database I/O operations.
  public var dbQueue: DatabaseQueue?

  public func openDatabase() throws {
    precondition(dbQueue == nil)
    dbQueue = try DatabaseQueue(path: url.appendingPathComponent("collection.anki2").path)
  }

  /// Debug routine: Deletes everything that's currently in the container.
  public func emptyContainer() throws {
    precondition(dbQueue == nil)
    let items = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    for item in items {
      try FileManager.default.removeItem(at: item)
    }
  }

  /// Imports a "apkg" package into this database.
  /// - note: Currently this just copies the collection.anki2 entry out of the file and overwrites the container database with it.
  public func importPackage(_ packageUrl: URL) throws {
    guard let zipper = Zipper.read(at: packageUrl) else {
      logger.error("Could not open zip file at \(packageUrl)")
      throw Error.couldNotLoadPackage
    }
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki2" {
        _ = try zipper.extract(entry, to: url.appendingPathComponent("collection.anki2"))
        return
      }
    }
    throw Error.noDatabaseInPackage
  }

  /// Cache of all notes in the database. Update by calling `fetchNotes()`
  @Published public private(set) var notes: [Note] = []

  /// Fetches all notes in the database and stores them in `notes`
  public func fetchNotes() throws {
    notes = try dbQueue!.read { db -> [Note] in
      try Note.fetchAll(db)
    }
  }
}
