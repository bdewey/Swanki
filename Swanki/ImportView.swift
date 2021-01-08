// Copyright © 2019-present Brian Dewey.

import SwiftUI

struct ImportView: UIViewControllerRepresentable {
  var didPickURL: ((URL) -> Void)? = nil

  func makeUIViewController(
    context: UIViewControllerRepresentableContext<ImportView>
  ) -> UIDocumentPickerViewController {
    let viewController = UIDocumentPickerViewController(documentTypes: ["org.brians-brain.anki-package"], in: .import)
    viewController.delegate = context.coordinator
    return viewController
  }

  func updateUIViewController(
    _ uiViewController: UIDocumentPickerViewController,
    context: UIViewControllerRepresentableContext<ImportView>
  ) {
    // ??
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, UIDocumentPickerDelegate {
    let view: ImportView

    init(_ view: ImportView) {
      self.view = view
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      guard let url = urls.first else { return }
      logger.debug("Importing content from \(url)")
      view.didPickURL?(url)
    }
  }
}

struct ImportView_Previews: PreviewProvider {
  static var previews: some View {
    ImportView()
  }
}
