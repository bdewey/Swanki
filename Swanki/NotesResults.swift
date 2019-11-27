// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

/// Holds the results of a SELECT of Note data from a CollectionDatabase.
public final class NotesResults: ObservableObject {
  public init(
    database: CollectionDatabase,
    query: QueryInterfaceRequest<Note>
  ) {
    self.database = database
    self.query = query
  }

  /// The underlying database.
  public let database: CollectionDatabase

  /// The query.
  public let query: QueryInterfaceRequest<Note>

  /// The actual notes.
  @Published public private(set) var notes: [Note] = []

  /// Fetches the notes.
  @discardableResult
  public func fetch(completion: ((Result<[Note], Error>) -> Void)? = nil) -> Self {
    database.dbQueue!.asyncRead { databaseResult in
      let queryResult = databaseResult.flatMap { db in
        Result { try self.query.fetchAll(db) }
      }
      self.updateNotes(queryResult, completion: completion)
    }
    return self
  }

  /// Updates a note.
  public func updateNote(_ note: Note, completion: ((Result<[Note], Error>) -> Void)? = nil) {
    database.dbQueue!.asyncWrite({ db -> [Note] in
      try note.update(db)
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }
}

private extension NotesResults {
  /// Updates the notes array with a new result.
  private func updateNotes(
    _ result: Result<[Note], Error>,
    completion: ((Result<[Note], Error>) -> Void)?
  ) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.updateNotes(result, completion: completion)
      }
      return
    }
    completion?(result)
    _ = result.map { notes = $0 }
  }
}
