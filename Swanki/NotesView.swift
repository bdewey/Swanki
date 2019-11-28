// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  @ObservedObject var notesResults: NotesResults

  @State private var draftNote: DraftNote?

  var body: some View {
    List {
      ForEach(notesResults.notes) { note in
        HStack {
          Text(note.fieldsArray.first ?? "")
            .lineLimit(1)
          Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
          self.draftNote = DraftNote(
            title: "Edit",
            note: note,
            commitAction: { self.notesResults.updateNote($0) }
          )
        }
      }
      .onDelete(perform: deleteNotes)
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

  private func deleteNotes(at indexes: IndexSet) {
    let victims = indexes.map { notesResults.notes[$0] }
    notesResults.deleteNotes(victims)
  }

  private func newNoteAction() {
    guard let (note, model) = notesResults.noteFactory() else {
      return
    }
    draftNote = DraftNote(title: "New", note: note, commitAction: { newNote in
      self.notesResults.insertNote(newNote, model: model)
    })
  }
}
