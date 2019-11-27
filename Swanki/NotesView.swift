// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  @ObservedObject var notesResults: NotesResults

  @State private var editingNote: BindableNote?

  var body: some View {
    List(notesResults.notes) { note in
      Text(note.fieldsArray.first ?? "")
        .lineLimit(1)
        .onTapGesture {
          self.editingNote = BindableNote(note)
        }
    }
    .navigationBarTitle("Notes", displayMode: .inline)
    .sheet(item: $editingNote) { _ in
      NoteView(
        note: self.$editingNote,
        saveAction: { self.notesResults.updateNote($0) }
      ).environmentObject(self.collectionDatabase)
    }
  }
}
