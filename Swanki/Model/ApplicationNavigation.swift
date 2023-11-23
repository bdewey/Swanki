// Copyright © 2019-present Brian Dewey.

import Observation
import SwiftData

@Observable
/// The navigation model that holds the selected deck and note.
final class ApplicationNavigation {
  var selectedDeck: Deck? {
    didSet {
      selectedNote = nil
    }
  }

  var selectedNote: PersistentIdentifier?
}
