// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

extension ModelContainer {
  @MainActor
  static let previews: ModelContainer = {
    let container = try! ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    let deck = Deck(name: "Sample Data")
    let note = Note(deck: deck, modificationTime: .now, fields: ["Front text", "Back text"])
    let card = Card(deck: deck, note: note, type: .frontThenBack)
    let reversedCard = Card(deck: deck, note: note, type: .backThenFront)
    container.mainContext.insert(deck)
    container.mainContext.insert(note)
    container.mainContext.insert(card)
    container.mainContext.insert(reversedCard)

    // Create a bunch of dummy cards
    for i in 1 ... 40 {
      let dummyNote = Note(deck: deck, modificationTime: .now, fields: ["Dummy front \(i)", "Dummy back \(i)"])
      let dummyCard = Card(type: .frontThenBack)
      let dummyReversedCard = Card(type: .backThenFront)
      container.mainContext.insert(dummyNote)
      container.mainContext.insert(dummyCard)
      container.mainContext.insert(dummyReversedCard)
      dummyCard.deck = deck
      dummyCard.note = dummyNote
      dummyReversedCard.deck = deck
      dummyReversedCard.note = dummyNote
    }
    return container
  }()
}
