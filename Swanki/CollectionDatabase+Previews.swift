// Copyright © 2019-present Brian Dewey.

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
      return collectionDatabase
    } catch {
      fatalError("Could not make database: \(error)")
    }
  }()
}

extension Card {
  static let nileCard = Card(
    id: 1334609482913,
    noteID: 1334609482913,
    deckID: 1342706224003,
    templateIndex: 0,
    modificationTimeSeconds: 1345898758,
    queue: .new,
    due: 113,
    type: .new,
    interval: 0,
    factor: 2500,
    reps: 0,
    lapses: 0,
    left: 0
  )
}

extension Note {
  static let nileRiver = Note(
    id: 1334609482913,
    guid: "abcdefg",
    modelID: 1342706223926,
    modifiedTimestampSeconds: 1342706224,
    usn: -1,
    tags: " AncientHistory Egypt Geography ",
    encodedFields: [
      "Just prior to going into the Mediterranean Sea the Nile River branches out in numerous directions and forms what?<br /><br /><img src=\"pastewpyb0f.jpg\" />",
      "The Nile Delta.",
    ].joined(separator: "\u{1F}")
  )
}

extension NoteModel {
  static let basic = NoteModel(
    id: 1342706223926,
    name: "Basic",
    requirements: [],
    css: ".card {\n font-family: arial;\n font-size: 20px;\n text-align: center;\n color: black;\n background-color: white;\n}\n\n.card1 { background-color: #ffffff;text-align: left }",
    deckID: 1342706224003,
    fields: [
      NoteField(font: "Arial", name: "Front", ord: 0),
      NoteField(font: "Arial", name: "Back", ord: 1),
    ],
    modelType: .standard,
    templates: [
      CardTemplate(
        name: "Forward",
        afmt: "{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}",
        bafmt: "",
        bqfmt: "",
        ord: 0,
        qfmt: "{{Front}}"
      ),
    ]
  )
}
