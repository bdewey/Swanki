// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

extension ModelContainer {
  @MainActor
  static let previews: ModelContainer = {
    let container = try! ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    let deck = Deck(name: "Sample Data")
    container.mainContext.insert(deck)
    let note = Note(deck: deck, modificationTime: .now, fields: ["Front text", "Back text"])
    note.addCard {
      Card(type: .frontThenBack)
    }
    note.addCard {
      Card(type: .backThenFront)
    }

    // Create a bunch of dummy cards
    for i in 1 ... 40 {
      let dummyNote = deck.addNote {
        Note(modificationTime: .now, fields: ["Dummy front \(i)", "Dummy back \(i)"])
      }
      dummyNote.addCard {
        Card(type: .frontThenBack)
      }
      dummyNote.addCard {
        Card(type: .backThenFront)
      }
    }
    return container
  }()
}
