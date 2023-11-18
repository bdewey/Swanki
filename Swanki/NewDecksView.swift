// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Show all of the decks in a database.
struct NewDecksView: View {
  @Query private var decks: [Deck]
  @Environment(\.modelContext) private var modelContext
  @State private var editingDeck: Deck?
  @State private var shouldShowNewDeck = false

  var body: some View {
    List {
      ForEach(decks) { deck in
        NavigationLink {
          NewNotesView(deck: deck)
        } label: {
          HStack {
            Text(deck.name)
            Spacer()
            Button {
              editingDeck = deck
            } label: {
              Image(systemName: "info.circle")
            }
          }
        }
      }
      .onDelete(perform: { indexSet in
        for index in indexSet {
          modelContext.delete(decks[index])
        }
      })
    }
    .sheet(item: $editingDeck) { deck in
      NavigationStack {
        EditDeckView(deck: deck)
      }
    }
    .sheet(isPresented: $shouldShowNewDeck) {
      NavigationStack {
        EditDeckView(deck: nil)
      }
    }
    .navigationTitle("Decks")
    .toolbar {
      Button {
        shouldShowNewDeck = true
      } label: {
        Label("Add", systemImage: "plus")
      }
    }
  }
}

struct EditDeckView: View {
  var deck: Deck?

  @State private var name: String = ""
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  var body: some View {
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
    .onAppear {
      if let deck {
        name = deck.name
      }
    }
  }
}

#Preview {
  NavigationStack {
    NewDecksView()
  }
  .modelContainer(.previews)
}
