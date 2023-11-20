// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

private extension Note {
  static func forDeck(_ deck: Deck) -> Predicate<Note> {
    let id = deck.id
    return #Predicate<Note> { note in
      note.deck?.id == id
    }
  }
}

struct NewNotesView: View {
  init(deck: Deck) {
    self.deck = deck
    self._notes = Query(filter: Note.forDeck(deck))
  }

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
        EditNoteView(deck: deck, note: note)
      }
    }
    .sheet(isPresented: $isShowingNewNote) {
      NavigationStack {
        EditNoteView(deck: deck)
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

struct StudySessionLoader: View {
  let deck: Deck
  @State private var studySession: NewStudySession?
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ZStack {
      if let studySession {
        StudySessionView(studySession: studySession)
      } else {
        ProgressView()
      }
    }
    .onAppear {
      studySession = NewStudySession(modelContext: modelContext, deck: deck, newCardLimit: 20)
      do {
        try studySession?.loadCards(dueBefore: .now)
      } catch {
        logger.error("Unexpected error loading cards: \(error)")
      }
    }
  }
}

@MainActor
struct StudySessionView: View {
  var studySession: NewStudySession

  var body: some View {
    Self._printChanges()
    return ZStack {
      if let card = studySession.currentCard {
        CardQuizView(card: card) { answer, item, studyTime in
          do {
            try studySession.updateCurrentCardSchedule(answer: answer, schedulingItem: item, studyTime: studyTime, currentDate: .now)
          } catch {
            logger.error("Unexpected error scheduling card \(card.id) and answer \(answer.localizedName): \(error)")
          }
        }
      } else {
        ContentUnavailableView {
          Label("Nothing to study!", systemImage: "nosign")
        } description: {
          Text("No more cards!")
        }
      }
    }
  }
}

struct EditNoteView: View {
  var deck: Deck
  var note: Note? = nil

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var front: String = ""
  @State private var back: String = ""

  var body: some View {
    Form {
      TextField("Front", text: $front)
      TextField("Back", text: $back)
    }
    .navigationTitle(note == nil ? "New Note" : "Edit Note")
    .onAppear {
      if let note {
        front = note.field(at: 0) ?? ""
        back = note.field(at: 1) ?? ""
      }
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          let n = confirmationNote
          n.fields = [front, back]
          n.modificationTime = .now
          dismiss()
        } label: {
          Text("Done")
        }
      }
      ToolbarItem(placement: .cancellationAction) {
        Button {
          dismiss()
        } label: {
          Text("Cancel")
        }
      }
    }
  }

  private var confirmationNote: Note {
    if let note {
      return note
    } else {
      let note = deck.addNote()
      note.addCard {
        Card(type: .frontThenBack)
      }
      note.addCard {
        Card(type: .backThenFront)
      }
      return note
    }
  }
}

private struct SelectDeckView: View {
  @Query var decks: [Deck]

  var body: some View {
    if decks.count > 0 {
      NewNotesView(deck: decks[0])
    }
  }
}

#Preview {
  NavigationStack {
    SelectDeckView()
  }
  .modelContainer(.previews)
}
