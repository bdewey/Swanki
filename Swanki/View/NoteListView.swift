// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Displays the list of ``Note`` objects in a ``Deck``.
struct NoteListView: View {
  init(deck: Deck) {
    self.deck = deck
    self._notes = Query(filter: Note.forDeck(deck))
  }

  /// The ``Deck`` we are examining.
  var deck: Deck

  @State private var editingNote: Note?
  @State private var isShowingNewNote = false
  @State private var isShowingStudySession = false
  @Environment(\.modelContext) private var modelContext

  @Query private var notes: [Note]

  var body: some View {
    List {
      ForEach(notes) { note in
        HStack {
          Text(note.fields.first ?? "??")
          Spacer()
          Button {
            editingNote = note
          } label: {
            Image(systemName: "info.circle")
          }
        }
      }
      .onDelete(perform: { indexSet in
        for index in indexSet {
          modelContext.delete(notes[index])
        }
      })
    }
    .navigationTitle(deck.name)
    .sheet(item: $editingNote) { note in
      NavigationStack {
        NoteEditor(deck: deck, note: note)
      }
    }
    .sheet(isPresented: $isShowingNewNote) {
      NavigationStack {
        NoteEditor(deck: deck)
      }
    }
    .sheet(isPresented: $isShowingStudySession) {
      StudySessionLoader(deck: deck)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          isShowingNewNote = true
        } label: {
          Label("New", systemImage: "plus")
        }
      }
      ToolbarItem(placement: .secondaryAction) {
        Button {
          isShowingStudySession = true
        } label: {
          Label("Study", systemImage: "rectangle.on.rectangle.angled")
        }
      }
    }
  }
}

private struct SelectDeckView: View {
  @Query var decks: [Deck]

  var body: some View {
    if decks.count > 0 {
      NoteListView(deck: decks[0])
    }
  }
}

#Preview {
  NavigationStack {
    SelectDeckView()
  }
  .modelContainer(.previews)
}
