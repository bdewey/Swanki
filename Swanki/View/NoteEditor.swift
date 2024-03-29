// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// Allows creating or editing a ``Note``.
///
/// - warning: Right now the only "shape" of a ``Note`` that we support is one with a "front" and "back" field and that has two associated ``Card`` objects.
struct NoteEditor: View {
  var deck: Deck
  @Bindable var note: Note

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    Form {
      TextField("Front", text: $note.front.defaultEmpty)
      TextField("Back", text: $note.back.defaultEmpty)
    }
  }
}
