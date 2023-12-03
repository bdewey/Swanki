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
    let stats = summaryStatistics
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

  private var summaryStatistics: SummaryStatistics {
    guard let modelContext = deck.modelContext else {
      logger.warning("Trying to get statistics when the deck has not been saved")
      return SummaryStatistics()
    }
    do {
      return try modelContext.summaryStatistics(deck: deck)
    } catch {
      logger.error("Error fetching summary statistics: \(error)")
      return SummaryStatistics()
    }
  }

  private var atRiskXP: Int {
    guard let modelContext = deck.modelContext else {
      logger.warning("Trying to get XP when the deck has not been saved")
      return 0
    }
    do {
      let todayStats = try modelContext.summaryStatistics(deck: deck)
      let tomorrowStats = try modelContext.summaryStatistics(on: .now.addingTimeInterval(.day), deck: deck)
      return todayStats.xp - tomorrowStats.xp
    } catch {
      logger.error("Error fetching summary statistics: \(error)")
      return 0
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
  .withPreviewEnvironment()
}
