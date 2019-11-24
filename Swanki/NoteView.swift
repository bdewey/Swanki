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
            // TODO: I want to set the height to contentSize.height. How do I do that?
            // Maybe I need a Binding<CGFloat> per section, and then I can write the desired height
            // into that binding?
            HtmlEditorViewWrapper(
              html: section.contents,
              baseURL: self.collectionDatabase.url
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
      .map({ $0.name })
  }

  private var cancelButton: some View {
    Button(action: { self.note = nil }, label: { Text("Cancel")})
  }

  private struct NoteSection: Identifiable {
    let title: String
    let contents: String

    var id: String { title }
  }
}

struct HtmlEditorViewWrapper: View {
  /// The HTML content to edit.
  // TODO: Turn this into a binding!
  let html: String

  /// The base URL from which to load images.
  let baseURL: URL

  @State var desiredHeight: CGFloat = 100

  var body: some View {
    HtmlEditorView(html: html, baseURL: baseURL, desiredHeight: $desiredHeight)
      .frame(height: desiredHeight)
  }
}
