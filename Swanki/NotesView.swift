// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

/// Displays all of the notes in a particular deck.
struct NotesView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  /// The deck to show.
  // TODO: We currently don't filter on this value.
  let deckID: Int

  var body: some View {
    List(collectionDatabase.notes) { note in
      Text(note.fieldsArray.first ?? "").lineLimit(1)
    }.navigationBarTitle("Notes", displayMode: .inline)
  }
}
