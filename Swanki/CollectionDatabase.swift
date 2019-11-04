// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB
import Logging
import Zipper

/// Holds the database containing the Anki collection.
public final class CollectionDatabase: ObservableObject {
  public enum Error: Swift.Error {
    case couldNotLoadPackage
    case noDatabaseInPackage
    case unknownDeck(deckID: Int)
    case unknownNote(noteID: Int)
    case unknownNoteModel(modelID: Int)
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
    let mediaMap = zipper.mediaMap
    logger.info("Media map: \(mediaMap)")
    var didExtractDatabase = false
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki2" {
        _ = try zipper.extract(entry, to: url.appendingPathComponent("collection.anki2"))
        didExtractDatabase = true
      }
      if let destinationMedia = mediaMap[entry.path] {
        logger.info("Extracting \(entry.path) to \(destinationMedia)")
        _ = try zipper.extract(entry, to: url.appendingPathComponent(destinationMedia))
      }
    }
    if !didExtractDatabase {
      throw Error.noDatabaseInPackage
    }
  }

  public private(set) var noteModels: [Int: NoteModel] = [:]
  public private(set) var deckModels: [Int: DeckModel] = [:]
  public private(set) var deckConfigs: [Int: DeckConfig] = [:]

  public func fetchMetadata() throws {
    guard let collectionMetadata = try dbQueue!.read({ db -> CollectionMetadata? in
      try CollectionMetadata.fetchOne(db)
    }) else {
      return
    }
    let noteModels = try collectionMetadata.loadModels()
    let deckModels = try collectionMetadata.loadDecks()
    let deckConfigs = try collectionMetadata.loadDeckConfigs()

    objectWillChange.send()
    self.noteModels = noteModels
    self.deckModels = deckModels
    self.deckConfigs = deckConfigs
  }

  /// Cache of all notes in the database. Update by calling `fetchNotes()`
  @Published public private(set) var notes: [Note] = []

  /// Fetches all notes in the database and stores them in `notes`
  public func fetchNotes() throws {
    notes = try dbQueue!.read { db -> [Note] in
      try Note.fetchAll(db)
    }
  }

  public func fetchNote(id: Int) throws -> Note? {
    try dbQueue!.read { db -> Note? in
      try Note
        .filter(Column("id") == id)
        .fetchOne(db)
    }
  }

  public func fetchNewCards(from deckID: Int) throws -> [Card] {
    let limit = try newCardLimit(for: deckID)
    return try dbQueue!.read { db -> [Card] in
      try Card
        .filter(Column("did") == deckID)
        .order(Column("due").asc)
        .limit(limit)
        .fetchAll(db)
    }
  }

  /// How many new cards per day we are supposed to study from deck `deckID`
  public func newCardLimit(for deckID: Int) throws -> Int {
    guard
      let deck = deckModels[deckID],
      let config = deckConfigs[deck.configID]
    else {
      throw Error.unknownDeck(deckID: deckID)
    }
    return config.new.perDay
  }

  public func recordAnswer(_ answer: CardAnswer, for card: Card) throws {
    guard
      let model = deckModels[card.deckID],
      let config = deckConfigs[model.configID]
    else {
      throw Error.unknownDeck(deckID: card.deckID)
    }
    var card = card
    card.reps += 1
    if card.queue == .new {
      card.queue = .learning
      card.type = .learning
      card.left = startingLeft(for: card, config: config)
    }
    switch card.queue {
    case .learning, .futureLearning:
      recordAnswer(answer, forLearningCard: &card, config: config)
    case .due:
      recordAnswer(answer, forReviewCard: &card)
    default:
      preconditionFailure()
    }
    try dbQueue?.write({ db in
      try card.update(db)
    })
  }

  private func recordAnswer(_ answer: CardAnswer, forLearningCard card: inout Card, config: DeckConfig) {
    switch answer {
    case .again:
      card.left = startingLeft(for: card, config: config)
    case .good:
      card.left -= 1
      if card.left <= 0 {
        convertLearningCardToReviewCard(&card, config: config)
      } else {
        moveCardToNextStep(&card, config: config)
      }
    case .hard:
      // Don't advance to the next step.
      // TODO: Make the delay be halfway between the two delay values
      // FIX: "moveCardToNextStep" doesn't actually change the "left" count so it's a misnomer
      moveCardToNextStep(&card, config: config)
    case .easy:
      convertLearningCardToReviewCard(&card, config: config)
    }
  }

  // Anki schedv2 uses a separate queue for "cards to learn today" and "cards still learning but scheduled on another day" -- not sure I want to copy that.
  private func moveCardToNextStep(_ card: inout Card, config: DeckConfig) {
    precondition(card.left > 0 && card.left < config.new.delays.count)
    let delayIndex = config.new.delays.count - card.left - 1
    assert(delayIndex >= 0 && delayIndex < config.new.delays.count)
    let delayMinutes = config.new.delays[delayIndex]
    card.due = Int(round(Date().addingTimeInterval(TimeInterval(delayMinutes) * .minute).timeIntervalSinceReferenceDate))
  }

  private func convertLearningCardToReviewCard(_ card: inout Card, config: DeckConfig) {
    card.interval = graduatingInterval(card: card, config: config, early: false)
    let dueDay = Date().addingTimeInterval(TimeInterval(card.interval) * .day).timeIntervalSinceReferenceDate / .day
    card.due = Int(round(dueDay))
    card.factor = config.new.initialFactor
    card.type = .due
  }

  private func graduatingInterval(card: Card, config: DeckConfig, early: Bool) -> Int {
    if card.type == .due || card.type == .filtered {
      return card.interval
    }
    let ideal = early ? config.new.ints[1] : config.new.ints[0]
    return fuzzRange(for: ideal).randomElement() ?? ideal
  }

  // Logic transcribed from Anki schedv2.py _fuzzIvlRange
  private func fuzzRange(for interval: Int) -> ClosedRange<Int> {
    if interval < 2 {
      return 1 ... 1
    }
    if interval == 2 {
      return 2 ... 3
    }
    var fuzz: Int
    if interval < 7 {
      fuzz = interval / 4
    }
    if interval < 30 {
      fuzz = max(2, Int(round(Double(interval) * 0.15)))
    } else {
      fuzz = max(4, Int(round(Double(interval) * 0.05)))
    }
    fuzz = max(1, fuzz)
    return (interval - fuzz)...(interval + fuzz)
  }

  private func recordAnswer(_ answer: CardAnswer, forReviewCard card: inout Card) {
    assertionFailure()
  }

  private func startingLeft(for card: Card, config: DeckConfig) -> Int {
    let left = config.new.delays.count
    // TODO: Update steps remaining today? I don't know, this seems dumb.
    return left
  }
}

private extension Zipper {
  var mediaMap: [String: String] {
    do {
      var mediaEntries: [String: String] = [:]
      if let mediaMapEntry = self["media"] {
        _ = try self.extract(mediaMapEntry) { data in
          mediaEntries = try JSONDecoder().decode([String: String].self, from: data)
        }
      }
      return mediaEntries
    } catch {
      logger.error("Unexpected error extracting media map from archive: \(error)")
      return [:]
    }
  }
}

private extension TimeInterval {
  static let day: TimeInterval = 60 * 60 * 24
  static let minute: TimeInterval = 60
}
