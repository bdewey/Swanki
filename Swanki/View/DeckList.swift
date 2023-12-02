// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Show all of the decks in a database.
struct DeckList: View {
  @Query private var decks: [Deck]
  @Environment(\.modelContext) private var modelContext
  @State private var editingDeck: Deck?
  @State private var shouldShowNewDeck = false
  @Environment(ApplicationNavigation.self) private var applicationNavigation
  @Environment(FileImportNavigation.self) private var fileImporterNavigation
  @Environment(StudySessionNavigation.self) private var studySessionNavigation
  @FocusState private var focusedEditor: UUID?
  @State private var isConfirmingDelete = false
  @State private var victims: IndexSet?

  var body: some View {
    @Bindable var applicationNavigation = applicationNavigation
    @Bindable var fileImporterNavigation = fileImporterNavigation
    VStack {
      List(selection: $applicationNavigation.selectedDeck) {
        #if !os(macOS)
          Button("Study", systemImage: "plus") {
            studySessionNavigation.isShowingStudySession = true
          }
          .disabled(studySessionNavigation.isDisabled)
        #endif
        Section("Decks") {
          ForEach(decks) { deck in
            @Bindable var deck = deck
            VStack {
              HStack {
                TextField("Name", text: $deck.name)
                  .focused($focusedEditor, equals: deck.id)
                Spacer()
                Text("\(deck.xp.formatted(.number.grouping(.automatic))) XP").foregroundColor(.secondary)
              }
            }
            .contextMenu {
              Button("Edit Name", systemImage: "square.and.pencil") {
                focusedEditor = deck.id
              }
              Button("Delete", systemImage: "trash") {
                guard let victimIndex = decks.firstIndex(where: { $0 == deck }) else {
                  return
                }
                victims = IndexSet(integer: victimIndex)
                isConfirmingDelete = true
              }
            }
            .tag(deck)
          }
          .onDelete(perform: { indexSet in
            victims = indexSet
            isConfirmingDelete = true
          })
        }
      }
      .listStyle(.sidebar)
      Text(studySessionNavigation.studySession.displaySummary)
    }
    .alert("Are you sure?", isPresented: $isConfirmingDelete, actions: {
      Button("Delete", systemImage: "trash", role: .destructive) {
        for index in victims ?? [] {
          modelContext.delete(decks[index])
        }
      }
    })
    .sheet(isPresented: $shouldShowNewDeck) {
      DeckEditor(deck: nil)
    }
    .navigationTitle("Decks")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          shouldShowNewDeck = true
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
      #if !os(macOS)
        ToolbarItem(placement: .secondaryAction) {
          Button {
            logger.debug("Presenting file importer. Home directory is \(URL.homeDirectory.path)")
            fileImporterNavigation.isShowingFileImporter = true
          } label: {
            Label("Import", systemImage: "square.and.arrow.down.on.square")
          }
        }
      #endif
    }
  }

  private func importPackage(at url: URL) {
    logger.info("Trying to import Anki package at url \(url)")
    let importer = AnkiPackageImporter(packageURL: url, modelContext: modelContext)
    do {
      try importer.importPackage()
      logger.info("Import complete")
    } catch {
      logger.error("Error importing package at \(url): \(error)")
    }
  }
}

extension ApplicationNavigation {
  static let previews = ApplicationNavigation()
}

extension FileImportNavigation {
  static let previews = FileImportNavigation()
}

extension StudySessionNavigation {
  static let previews = StudySessionNavigation()
}

#Preview {
  NavigationStack {
    DeckList()
  }
  .environment(ApplicationNavigation.previews)
  .environment(FileImportNavigation.previews)
  .environment(StudySessionNavigation.previews)
  .modelContainer(.previews)
}
