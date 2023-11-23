// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
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
      .fileImporter(isPresented: $fileImportNavigation.isShowingFileImporter, allowedContentTypes: [.ankiPackage]) { result in
        guard let url = try? result.get() else { return }
        importPackage(at: url)
      }
      .onOpenURL { url in
        logger.info("Trying to open url \(url)")
        importPackage(at: url)
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

extension View {
  func allowFileImports(fileImportNavigation: FileImportNavigation) -> some View {
    modifier(AllowFileImportsModifier(fileImportNavigation: fileImportNavigation))
  }
}
