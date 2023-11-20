// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// Allows creating or editing a ``Note``.
///
/// - warning: Right now the only "shape" of a ``Note`` that we support is one with a "front" and "back" field and that has two associated ``Card`` objects.
struct NoteEditor: View {
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
