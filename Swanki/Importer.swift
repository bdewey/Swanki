// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import Logging
import Zipper

private let logger: Logger = {
  var logger = Logger(label: "org.brians-brain.Swanki.importer")
  logger.logLevel = .debug
  return logger
}()

enum Importer {
  enum Error: Swift.Error {
    case noDatabaseInPackage
    case couldNotLoadPackage
  }

  static func importPackage(_ packageUrl: URL) throws -> TemporaryFile {
    guard let zipper = Zipper.read(at: packageUrl) else {
      logger.error("Could not open zip file at \(packageUrl)")
      throw Error.couldNotLoadPackage
    }
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki2" {
        let tempDirectory = try TemporaryFile(creatingTempDirectoryForFilename: "collection.anki2")
        _ = try zipper.extract(entry, to: tempDirectory.fileURL)
        return tempDirectory
      }
    }
    throw Error.noDatabaseInPackage
  }
}
