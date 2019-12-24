// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  @ObservedObject var notesResults: ObservableDeck

  @State private var draftNote: DraftNote?
  @State private var showNoteTypeSheet: Bool = false

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
          do {
            let noteModel = try self.collectionDatabase.noteModel(for: note)
            self.draftNote = DraftNote(
              title: "Edit",
              note: note,
              noteModel: noteModel,
              commitAction: { self.notesResults.updateNote($0) }
            )
          } catch {
            logger.error("Unexpected error preparing draft note: \(error)")
          }
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
    .actionSheet(isPresented: $showNoteTypeSheet, content: { self.noteActionSheet })
    .navigationBarItems(trailing: newNoteButton)
  }

  private var newNoteButton: some View {
    Button(action: newNoteAction) {
      Image(systemName: "plus.circle")
    }.disabled(eligibleNoteModels.isEmpty)
  }

  private func deleteNotes(at indexes: IndexSet) {
    let victims = indexes.map { notesResults.notes[$0] }
    notesResults.deleteNotes(victims)
  }

  private var eligibleNoteModels: [NoteModel] {
    collectionDatabase.noteModels.values
      .filter { $0.modelType == .standard }
  }

  private var noteActionSheet: ActionSheet {
    var buttons = eligibleNoteModels
      .map { model in
        ActionSheet.Button.default(Text(verbatim: model.name), action: { self.draftNote = self.makeDraftNote(from: model) })
      }
    buttons.append(.cancel())
    return ActionSheet(title: Text("Type"), message: nil, buttons: buttons)
  }

  private func makeDraftNote(from model: NoteModel) -> DraftNote {
    let note = Note.makeEmptyNote(modelID: model.id, fieldCount: model.fields.count)
    return DraftNote(title: "New", note: note, noteModel: model) { updatedNote in
      self.notesResults.insertNote(updatedNote, model: model)
    }
  }

  private func newNoteAction() {
    showNoteTypeSheet = true
  }
}
