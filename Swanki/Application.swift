// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

@MainActor
@main
struct Application: App {
  @State private var selectedDeck: Deck?
  @State private var selectedNote: PersistentIdentifier?

  var body: some Scene {
    WindowGroup {
      NavigationSplitView {
        DeckList(selectedDeck: $selectedDeck)
      } detail: {
        if let selectedDeck {
          NoteListView(deck: selectedDeck, selectedNote: $selectedNote)
        }
      }
      .modelContainer(for: Deck.self, isUndoEnabled: true)
      .onChange(of: selectedDeck, initial: false) {
        selectedNote = nil
      }
    }
  }
}
