// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
@main
struct Application: App {
  @State private var selectedDeck: Deck?
  @State private var selectedNote: Note?

  var body: some Scene {
    WindowGroup {
      NavigationSplitView {
        DeckList(selectedDeck: $selectedDeck)
      } content: {
        if let selectedDeck {
          NoteListView(deck: selectedDeck, selectedNote: $selectedNote)
        }
      } detail: {
        if let selectedDeck, let selectedNote {
          NoteEditor(deck: selectedDeck, note: $selectedNote)
        }
      }
      .modelContainer(for: Deck.self)
      .onChange(of: selectedDeck, initial: false) {
        selectedNote = nil
      }
    }
  }
}
