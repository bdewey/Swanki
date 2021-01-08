// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// Displays (& optionally edits) a single note. Designed to be displayed as a modal.
struct NoteView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  @Binding var note: DraftNote?
  @State var firstResponderIndex = 0

  var body: some View {
    NavigationView {
      Form {
        ForEach(sections) { section in
          Section(header: Text(section.title)) {
            HTMLView(
              title: section.title,
              html: self.note?.field(at: section.index) ?? .constant("WTF"),
              baseURL: self.collectionDatabase.url,
              backgroundColor: .secondarySystemGroupedBackground,
              keyCommands: self.keyCommands,
              shouldBeFirstResponder: self.firstResponderIndex == section.index
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

  private var keyCommands: [HTMLView.KeyCommand] {
    var commands = [
      HTMLView.KeyCommand(input: String(.tab), modifierFlags: [], action: nextField),
      HTMLView.KeyCommand(input: String(.tab), modifierFlags: [.shift], action: previousField),
    ]
    commands.append(contentsOf: Character.paragraphBreakingCharacters.map {
      HTMLView.KeyCommand(input: String($0), modifierFlags: [], action: nextFieldOrDone)
    })
    return commands
  }

  private var noteModel: NoteModel? {
    guard let note = note else { return nil }
    return collectionDatabase.noteModels[note.id]
  }

  private func nextField() {
    firstResponderIndex = min(firstResponderIndex + 1, sections.count - 1)
  }

  private func nextFieldOrDone() {
    if firstResponderIndex == sections.count - 1, (note?.completeCardCount ?? 0) > 0 {
      saveNote()
    } else {
      nextField()
    }
  }

  private func previousField() {
    firstResponderIndex = max(firstResponderIndex - 1, 0)
  }

  private var cancelButton: some View {
    Button(action: { self.note = nil }, label: { Text("Cancel") })
  }

  private var doneButton: some View {
    Button(action: saveNote, label: { Text("Done").bold() })
      .disabled((note?.completeCardCount ?? 0) == 0)
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
