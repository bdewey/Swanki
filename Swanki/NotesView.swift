// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  @ObservedObject var notesResults: NotesResults

  @State private var draftNote: DraftNote?

  var body: some View {
    List(notesResults.notes) { note in
      Text(note.fieldsArray.first ?? "")
        .lineLimit(1)
        .onTapGesture {
          self.draftNote = DraftNote(
            title: "Edit",
            note: note,
            commitAction: { self.notesResults.updateNote($0) }
          )
        }
    }
    .navigationBarTitle("Notes", displayMode: .inline)
    .sheet(item: $draftNote) { _ in
      NoteView(
        note: self.$draftNote
      ).environmentObject(self.collectionDatabase)
    }
    .navigationBarItems(trailing: newNoteButton)
  }

  private var newNoteButton: some View {
    Button(action: newNoteAction) {
      Image(systemName: "plus.circle")
    }
  }

  private func newNoteAction() {
    // This is an "empty" note associated with a random model.
    // TODO: Don't pick a random model.
    let note = notesResults.noteFactory()
    draftNote = DraftNote(title: "New", note: note, commitAction: { newNote in
      self.notesResults.insertNote(newNote)
    })
  }
}
