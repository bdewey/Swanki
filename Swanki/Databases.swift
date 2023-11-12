// Copyright © 2019-present Brian Dewey.

import Foundation

@MainActor
/// Holds an observable array of CollectionDatabase objects.
final class Databases: ObservableObject {
  init(_ databases: [CollectionDatabase] = []) {
    self.contents = databases
  }

  @Published private(set) var contents: [CollectionDatabase]

  private let homeDirectoryTask: Task<URL, Never> = Task.detached(priority: .userInitiated) {
    URL.determineHomeDirectory()
  }

  private static func determineHomeDirectory() -> URL {
    assert(!Thread.isMainThread)
    if let containerURL = FileManager.default.url(
      forUbiquityContainerIdentifier: "iCloud.org.brians-brain.Swanki"
    )?.appendingPathComponent("Documents") {
      logger.info("Using iCloud: \(containerURL)")
      return containerURL
    }
    let localURL = try! FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    logger.info("Using local URL: \(localURL)")
    return localURL
  }

  /// Looks for existing databases in the home directory and adds them to `contents`.
  /// Because determining the home directory is async,
  func lookForExistingDatabases() async -> [CollectionDatabase] {
    let homeDirectory = await homeDirectoryTask.value
    let homeDirectoryContents = (try? FileManager.default.contentsOfDirectory(at: homeDirectory, includingPropertiesForKeys: nil, options: [])) ?? []
    let databaseURLs = homeDirectoryContents.filter { $0.pathExtension == "swanki" }
    let openDatabases = databaseURLs.compactMap {
      do {
        let database = try self.openDatabase(at: $0)
        logger.info("Successfully opened database at \($0)")
        return database
      } catch {
        logger.error("Error opening database \($0): \(error)")
        return nil
      }
    }
    contents.append(contentsOf: openDatabases)
    return contents
  }

  func openDatabase(at url: URL, importing importURL: URL? = nil) throws -> CollectionDatabase {
    let database = CollectionDatabase(url: url)
    if let importURL {
      try database.importPackage(importURL)
    }
    try database.openDatabase()
    try database.fetchMetadata()
    NSFileCoordinator.addFilePresenter(database)
    return database
  }

  func didEnterBackground() {
    for database in contents {
      database.saveIfNeededAndLogError()
      NSFileCoordinator.removeFilePresenter(database)
    }
  }

  func willEnterForeground() {
    for database in contents {
      NSFileCoordinator.addFilePresenter(database)
    }
  }

  /// Imports an Anki package (zipped "apkg" file) into a Swanki database.
  func importPackage(at url: URL) async {
    let homeDirectory = await homeDirectoryTask.value
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

  func makeDemoDatabase() async {
    let homeDirectory = await homeDirectoryTask.value
    let demoURL = homeDirectory.appendingPathComponent("demo.swanki")
    do {
      let collectionDatabase = CollectionDatabase(url: demoURL)
      try collectionDatabase.openDatabase()
      try collectionDatabase.fetchMetadata()
      contents.append(collectionDatabase)
    } catch {
      let collectionDatabase = CollectionDatabase(url: demoURL)
      rebuildDemoDatabase(collectionDatabase)
      contents.append(collectionDatabase)
    }
  }

  private func makeDemoDatabase(in homeDirectory: URL) {
    let demoURL = homeDirectory.appendingPathComponent("demo.swanki")
    do {
      let collectionDatabase = CollectionDatabase(url: demoURL)
      try collectionDatabase.openDatabase()
      try collectionDatabase.fetchMetadata()
      contents.append(collectionDatabase)
    } catch {
      let collectionDatabase = CollectionDatabase(url: demoURL)
      rebuildDemoDatabase(collectionDatabase)
      contents.append(collectionDatabase)
    }
  }

  private func rebuildDemoDatabase(_ collectionDatabase: CollectionDatabase) {
    do {
      try collectionDatabase.emptyContainer()
      if let url = Bundle.main.url(forResource: "AncientHistory", withExtension: "apkg", subdirectory: "SampleData") {
        try collectionDatabase.importPackage(url)
      }
      try collectionDatabase.openDatabase()
      try collectionDatabase.fetchMetadata()
    } catch {
      fatalError("Could not create database: \(error)")
    }
  }
}

private extension URL {
  /// Determines the home directory to use for databases -- either local to the iPhone or the ubiquitous store.
  /// - note: Expensive; call on a background thread.
  static func determineHomeDirectory() -> URL {
    assert(!Thread.isMainThread)
    if let containerURL = FileManager.default.url(
      forUbiquityContainerIdentifier: "iCloud.org.brians-brain.Swanki"
    )?.appendingPathComponent("Documents") {
      logger.info("Using iCloud: \(containerURL)")
      return containerURL
    }
    let localURL = URL.homeDirectory
    logger.info("Using local URL: \(localURL)")
    return localURL
  }
}
