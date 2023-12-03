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
  @State private var isShowingInspector = false
  @Environment(\.modelContext) private var modelContext
  @Environment(ApplicationNavigation.self) private var applicationNavigation
  @Environment(StudySessionNavigation.self) private var studySessionNavigation

  @Query private var notes: [Note]

  var body: some View {
    @Bindable var applicationNavigation = applicationNavigation
    let stats = deck.summaryStatistics()
    VStack {
      DeckProgressChart(new: stats.newCardCount, learning: stats.learningCardCount, mastered: stats.masteredCardCount)
        .frame(height: 50)
        .padding()
      if atRiskXP > 0 {
        Text("You are at risk of losing **\(atRiskXP) XP**")
      }
      Table(notes, selection: $applicationNavigation.selectedNote) {
        TableColumn("Spanish", value: \.front.defaultEmpty)
        TableColumn("English", value: \.back.defaultEmpty)
      }
    }
    .navigationTitle(deck.name)
    .inspector(isPresented: $isShowingInspector, content: {
      NoteInspector(deck: deck, persistentIdentifier: applicationNavigation.selectedNote)
    })
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

  private var atRiskXP: Int {
    let todayStats = deck.summaryStatistics()
    let tomorrowStats = deck.summaryStatistics(on: .now.addingTimeInterval(.day))
    return todayStats.xp - tomorrowStats.xp
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
  .withPreviewEnvironment()
}
