// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
import SwiftData
import SwiftUI

@Observable
/// Navigation model that controls whether we show a file importer.
final class FileImportNavigation {
  var isShowingFileImporter = false
}

/// A modifier that allows the wrapped view to respond to ``FileImporterNavigation/isShowingFileImporter``.
struct AllowFileImportsModifier: ViewModifier {
  /// The Navigation model controlling whether we show the file importer.
  @Bindable var fileImportNavigation: FileImportNavigation

  /// The model context into which we import new models.
  @Environment(\.modelContext) private var modelContext

  func body(content: Content) -> some View {
    content
      .fileImporter(isPresented: $fileImportNavigation.isShowingFileImporter, allowedContentTypes: [.ankiPackage, .json]) { result in
        guard let url = try? result.get() else { return }
        Task {
          let success = url.startAccessingSecurityScopedResource()
          if success {
            await importPackage(at: url)
            url.stopAccessingSecurityScopedResource()
          } else {
            logger.error("Unable to access \(url)")
          }
        }
      }
      .onOpenURL { url in
        logger.info("Trying to open url \(url)")
        Task {
          await importPackage(at: url)
        }
      }
      .task {
        do {
          try await makeDefaultContent()
        } catch {
          logger.error("Error creating default content: \(error)")
        }
      }
      .environment(fileImportNavigation)
  }

  enum ImportError: Error {
    case noDefaultContent
  }

  private func makeDefaultContent() async throws {
    let deck = try Deck.spanishDeck(in: modelContext)
    if deck.notes?.isEmpty == false {
      logger.debug("No need to make default content because the Spanish deck has notes")
      return
    }
    guard let defaultContentURL = Bundle.main.url(forResource: "spanish-lesson-2", withExtension: "json", subdirectory: "SampleData") else {
      throw ImportError.noDefaultContent
    }
    try await importChatGPTJSON(url: defaultContentURL)
  }

  private func importPackage(at url: URL) async {
    do {
      switch url.pathExtension {
      case "apkg":
        logger.info("Trying to import Anki package at url \(url)")
        let importer = AnkiPackageImporter(packageURL: url, modelContext: modelContext)
        try importer.importPackage()
        logger.info("Import complete")
      case "json":
        logger.info("Trying to import ChatGPT JSON from url \(url)")
        try await importChatGPTJSON(url: url)
      default:
        logger.warning("Unrecognized url extension \(url.pathExtension) from \(url)")
      }
    } catch {
      logger.error("Error importing package at \(url): \(error)")
    }
  }

  private func makeNotesAndCards(json: ChatGPTVocabulary, deck: Deck) {
    for vocabularyItem in json.vocabulary {
      let note = deck.addNote {
        Note(
          modificationTime: .now,
          fields: [
            Note.Key.front.rawValue: vocabularyItem.spanish,
            Note.Key.back.rawValue: vocabularyItem.english,
            Note.Key.exampleSentenceSpanish.rawValue: vocabularyItem.exampleSentenceSpanish,
            Note.Key.exampleSentenceEnglish.rawValue: vocabularyItem.exampleSentenceEnglish,
          ]
        )
      }
      note.addCard(.frontThenBack)
      note.addCard(.backThenFront)
    }
  }

  @MainActor
  private func importChatGPTJSON(url: URL) async throws {
    let deck = try Deck.spanishDeck(in: modelContext)
    let (data, _) = try await URLSession.shared.data(from: url)

    do {
      let json = try JSONDecoder().decode(ChatGPTVocabulary.self, from: data)
      makeNotesAndCards(json: json, deck: deck)
    } catch {
      let jsonArray = try JSONDecoder().decode([ChatGPTVocabulary].self, from: data)
      for json in jsonArray {
        makeNotesAndCards(json: json, deck: deck)
      }
    }
  }
}

extension View {
  func allowFileImports(fileImportNavigation: FileImportNavigation) -> some View {
    modifier(AllowFileImportsModifier(fileImportNavigation: fileImportNavigation))
  }
}
