// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Displays the list of ``Note`` objects in a ``Deck``.
struct NoteList: View {
  init(deck: Deck) {
    self.deck = deck
    self._notes = Query(filter: Note.forDeck(deck))
  }

  /// The ``Deck`` we are examining.
  var deck: Deck

  @State private var editingNote: Note?
  @State private var isShowingNewNote = false
  @State private var isShowingStudySession = false
  @State private var isShowingInspector = false
  @Environment(\.modelContext) private var modelContext
  @Environment(ApplicationNavigation.self) private var applicationNavigation
  @Environment(StudySession.self) private var studySession: StudySession?

  @Query private var notes: [Note]

  var body: some View {
    @Bindable var applicationNavigation = applicationNavigation
    Table(notes, selection: $applicationNavigation.selectedNote) {
      TableColumn("Spanish", value: \.front)
      TableColumn("English", value: \.back)
    }
    .navigationTitle(deck.name)
    .inspector(isPresented: $isShowingInspector, content: {
      NoteInspector(deck: deck, persistentIdentifier: applicationNavigation.selectedNote)
    })
    .sheet(isPresented: $isShowingStudySession) {
      if let studySession {
        StudySessionView(studySession: studySession)
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          let newNote = makeNewNote()
          applicationNavigation.selectedNote = newNote.id
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
        .disabled(studySession == nil)
      }
      ToolbarItem(placement: .secondaryAction) {
        Toggle("Info", systemImage: "info.circle", isOn: $isShowingInspector)
      }
      ToolbarItem(placement: .secondaryAction) {
        Button {
          guard let selectedNote = applicationNavigation.selectedNote else {
            return
          }
          let model = modelContext.model(for: selectedNote)
          modelContext.delete(model)
        } label: {
          Label("Delete", systemImage: "trash")
        }
        .keyboardShortcut(.delete)
        .disabled(applicationNavigation.selectedNote == nil)
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
      NoteList(deck: decks[0])
    }
  }
}

#Preview {
  NavigationStack {
    SelectDeckView()
  }
  .environment(ApplicationNavigation.previews)
  .modelContainer(.previews)
}
