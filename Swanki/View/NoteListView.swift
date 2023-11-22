// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Displays the list of ``Note`` objects in a ``Deck``.
struct NoteListView: View {
  init(deck: Deck, selectedNote: Binding<PersistentIdentifier?>) {
    self.deck = deck
    self._selectedNote = selectedNote
    self._notes = Query(filter: Note.forDeck(deck))
  }

  /// The ``Deck`` we are examining.
  var deck: Deck
  @Binding var selectedNote: PersistentIdentifier?

  @State private var editingNote: Note?
  @State private var isShowingNewNote = false
  @State private var isShowingStudySession = false
  @State private var isShowingInspector = false
  @Environment(\.modelContext) private var modelContext

  @Query private var notes: [Note]

  var body: some View {
    Table(notes, selection: $selectedNote) {
      TableColumn("Spanish", value: \.front)
      TableColumn("English", value: \.back)
    }
    .navigationTitle(deck.name)
    .inspector(isPresented: $isShowingInspector, content: {
      NoteInspector(deck: deck, persistentIdentifier: selectedNote)
    })
    .sheet(isPresented: $isShowingStudySession) {
      StudySessionLoader(deck: deck)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          let newNote = makeNewNote()
          selectedNote = newNote.id
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
      ToolbarItem(placement: .secondaryAction) {
        Toggle("Info", systemImage: "info.circle", isOn: $isShowingInspector)
      }
      ToolbarItem(placement: .secondaryAction) {
        Button {
          guard let selectedNote else {
            return
          }
          let model = modelContext.model(for: selectedNote)
          modelContext.delete(model)
        } label: {
          Label("Delete", systemImage: "trash")
        }
        .keyboardShortcut(.delete)
        .disabled(selectedNote == nil)
      }
    }
  }

  private func makeNewNote() -> Note {
    let note = deck.addNote()
    note.addCard {
      Card(type: .frontThenBack)
    }
    note.addCard {
      Card(type: .backThenFront)
    }
    try? modelContext.save()
    return note
  }
}

struct NoteInspector: View {
  let deck: Deck
  let persistentIdentifier: PersistentIdentifier?

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    if let persistentIdentifier, let model = modelContext.model(for: persistentIdentifier) as? Note {
      NoteEditor(deck: deck, note: model)
    } else {
      ContentUnavailableView("No Note", systemImage: "exclamationmark.triangle")
    }
  }
}

private struct SelectDeckView: View {
  @Query var decks: [Deck]

  var body: some View {
    if decks.count > 0 {
      NoteListView(deck: decks[0], selectedNote: .constant(nil))
    }
  }
}

#Preview {
  NavigationStack {
    SelectDeckView()
  }
  .modelContainer(.previews)
}
