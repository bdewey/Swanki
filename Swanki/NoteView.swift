// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays (& optionally edits) a single note. Designed to be displayed as a modal.
struct NoteView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  @Binding var note: Note?

  var body: some View {
    NavigationView {
      Form {
        ForEach(sections) { section in
          Section(header: Text(section.title)) {
            HTMLView(
              title: section.title,
              html: section.contents,
              baseURL: self.collectionDatabase.url,
              isEditable: true,
              backgroundColor: .secondarySystemBackground
            )
          }
        }
      }
      .navigationBarItems(leading: cancelButton)
      .navigationBarTitle("Edit")
    }.navigationViewStyle(StackNavigationViewStyle())
  }

  private var sections: [NoteSection] {
    zip(fieldsNames, note?.fieldsArray ?? [])
      .map { NoteSection(title: $0, contents: $1) }
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

  private struct NoteSection: Identifiable {
    let title: String
    let contents: String

    var id: String { title }
  }
}
