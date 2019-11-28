// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays (& optionally edits) a single note. Designed to be displayed as a modal.
struct NoteView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  @Binding var note: DraftNote?

  var body: some View {
    NavigationView {
      Form {
        ForEach(sections) { section in
          Section(header: Text(section.title)) {
            HTMLView(
              title: section.title,
              html: self.note?.field(at: section.index) ?? .constant("WTF"),
              baseURL: self.collectionDatabase.url,
              backgroundColor: .secondarySystemBackground
            )
          }
        }
      }
      .navigationBarItems(leading: cancelButton, trailing: doneButton)
      .navigationBarTitle("Edit")
    }.navigationViewStyle(StackNavigationViewStyle())
  }

  private var sections: [NoteSection] {
    fieldsNames.enumerated().map { i, name -> NoteSection in
      NoteSection(title: name, index: i)
    }
  }

  private var fieldsNames: [String] {
    guard
      let note = note,
      let noteModel = collectionDatabase.noteModels[note.modelID]
    else {
      return []
    }
    return noteModel.fields
      .sorted(by: { $0.ord < $1.ord })
      .map { $0.name }
  }

  private var cancelButton: some View {
    Button(action: { self.note = nil }, label: { Text("Cancel") })
  }

  private var doneButton: some View {
    Button(action: saveNote, label: { Text("Done").bold() })
  }

  private func saveNote() {
    guard let noteWrapper = note else { return }
    note?.commitAction(noteWrapper.note)
    note = nil
  }

  private struct NoteSection: Identifiable {
    let title: String
    let index: Int

    var id: String { title }
  }
}
