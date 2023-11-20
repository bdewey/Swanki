// Copyright © 2019-present Brian Dewey.

import Foundation
import SwiftUI

/// A view for either editing or creating a new deck.
///
/// Expected to be presented in a sheet and creates its own NavigationStack for toolbars.
struct EditDeckView: View {
  var deck: Deck?

  @State private var name: String = ""
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $name)
      }
      .navigationTitle(deck == nil ? "New Deck" : "Edit Deck")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button {
            if let deck {
              deck.name = name
            } else {
              let deck = Deck(name: name)
              modelContext.insert(deck)
            }
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
    .onAppear {
      if let deck {
        name = deck.name
      }
    }
  }
}

#Preview {
  EditDeckView()
    .modelContainer(.previews)
}
