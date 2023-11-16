// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftData

extension ModelContainer {
  @MainActor
  static let previews: ModelContainer = {
    let container = try! ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    let deck = Deck(name: "Sample Data")
    let note = Note(deck: deck, modificationTime: .now, fields: ["Front text", "Back text"])
    let card = Card(deck: deck, note: note)
    container.mainContext.insert(deck)
    container.mainContext.insert(note)
    container.mainContext.insert(card)
    return container
  }()
}
