// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

extension ModelContainer {
  @MainActor
  static let previews: ModelContainer = {
    let container = try! ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.createSampleDeck(named: "Sample Data")
    return container
  }()

  @MainActor @discardableResult
  func createSampleDeck(named deckName: String, noteCount: Int = 40) -> Deck {
    let deck = Deck(name: deckName)
    mainContext.insert(deck)

    // Create a bunch of dummy cards
    for i in 1 ... noteCount {
      let dummyNote = deck.addNote {
        Note(modificationTime: .now, fields: ["front": "Dummy front \(i)", "back": "Dummy back \(i)"])
      }
      dummyNote.addCard {
        Card(type: .frontThenBack)
      }
      dummyNote.addCard {
        Card(type: .backThenFront)
      }
    }
    return deck
  }
}
