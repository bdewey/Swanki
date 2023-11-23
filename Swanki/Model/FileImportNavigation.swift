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
          await importPackage(at: url)
        }
      }
      .onOpenURL { url in
        logger.info("Trying to open url \(url)")
        Task {
          await importPackage(at: url)
        }
      }
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

  @MainActor
  private func importChatGPTJSON(url: URL) async throws {
    let (data, _) = try await URLSession.shared.data(from: url)
    let json = try JSONDecoder().decode(ChatGPTVocabulary.self, from: data)

    let deck = try Deck.spanishDeck(in: modelContext)
    for vocabularyItem in json.vocabulary {
      let note = deck.addNote {
        Note(
          modificationTime: .now,
          fields: [
            "front": vocabularyItem.spanish,
            "back": vocabularyItem.english,
            "exampleSentenceSpanish": vocabularyItem.exampleSentenceSpanish,
            "exampleSentenceEnglish": vocabularyItem.exampleSentenceEnglish,
          ]
        )
      }
      note.addCard(.frontThenBack)
      note.addCard(.backThenFront)
    }
  }
}

extension View {
  func allowFileImports(fileImportNavigation: FileImportNavigation) -> some View {
    modifier(AllowFileImportsModifier(fileImportNavigation: fileImportNavigation))
  }
}
