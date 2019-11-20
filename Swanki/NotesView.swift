// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  /// The deck to show.
  // TODO: We currently don't filter on this value.
  let deckID: Int

  @State private var editingNote: Note? = nil

  var body: some View {
    List(collectionDatabase.notes) { note in
      Text(note.fieldsArray.first ?? "")
        .lineLimit(1)
        .onTapGesture {
          self.editingNote = note
        }
    }
    .navigationBarTitle("Notes", displayMode: .inline)
    .sheet(item: $editingNote) { _ in
      NoteView(note: self.$editingNote).environmentObject(self.collectionDatabase)
    }
  }
}
