// Copyright © 2019 Brian's Brain. All rights reserved.

import Aztec
import Logging
import SwiftUI

private let layoutLogger: Logger = {
  var logger = Logger(label: "org.brians-brain.HTMLView.layout")
  logger.logLevel = .debug
  return logger
}()

struct HTMLView: View {
  /// the view title -- will be its accessibility label.
  let title: String

  /// The HTML content to edit.
  // TODO: Turn this into a binding!
  let html: String

  /// The base URL from which to load images.
  let baseURL: URL?

  /// If we should allow content editing
  var isEditable: Bool = false

  /// Background color for the editor.
  var backgroundColor: UIColor = .systemBackground

  /// Holds the height of the view. Will adjust to the content size of the actual content.
  @State private var desiredHeight: CGFloat = 100

  var body: some View {
    AztecView(
      html: html,
      baseURL: baseURL,
      isEditable: isEditable,
      backgroundColor: backgroundColor,
      desiredHeight: $desiredHeight
    )
    .frame(height: desiredHeight)
    .accessibility(label: Text(verbatim: title))
  }
}

private extension HTMLView {
  /// Instantiates an Aztec HTML editor.
  /// Assumes that there is a CollectionDatabase in the environment.
  struct AztecView: UIViewRepresentable {
    /// The HTML content to edit.
    // TODO: Turn this into a binding!
    let html: String

    /// The base URL from which to load images.
    let baseURL: URL?

    /// If we should allow content editing
    let isEditable: Bool

    let backgroundColor: UIColor

    @Binding var desiredHeight: CGFloat

    func makeUIView(context: UIViewRepresentableContext<AztecView>) -> Aztec.TextView {
      let textView = TextView(
        defaultFont: UIFont.preferredFont(forTextStyle: .body),
        defaultMissingImage: Images.defaultMissing
      )
      textView.textAttachmentDelegate = context.coordinator
      context.coordinator.textView = textView
      textView.layoutManager.delegate = context.coordinator
      return textView
    }

    func updateUIView(_ textView: TextView, context: UIViewRepresentableContext<AztecView>) {
      if html != context.coordinator.html {
        context.coordinator.html = html
        textView.suppressLayoutNotifications {
          textView.setHTML(html)
        }
      }
      textView.isEditable = isEditable
      textView.backgroundColor = backgroundColor
    }

    func makeCoordinator() -> Coordinator {
      return Coordinator(self)
    }

    /// Coordinator object -- serves as our delegate.
    final class Coordinator: NSObject, TextViewAttachmentDelegate {
      /// The associated view.
      var view: AztecView

      /// The most recent raw HTML string set on `view`
      var html: String?

      /// Weak reference to the assocated textView
      weak var textView: UITextView?

      init(_ view: AztecView) {
        self.view = view
      }

      func textView(
        _ textView: TextView,
        attachment: NSTextAttachment,
        imageAt url: URL,
        onSuccess success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping () -> Void
      ) {
        guard
          let resolvedURL = URL(string: url.relativeString, relativeTo: self.view.baseURL)
        else {
          failure()
          return
        }
        DispatchQueue.global(qos: .default).async {
          let image = (try? Data(contentsOf: resolvedURL)).flatMap { UIImage(data: $0) }
          DispatchQueue.main.async {
            if let image = image {
              success(image)
              logger.debug("Finished loading image, size = \(image.size)")
            } else {
              failure()
            }
          }
        }
        failure()
      }

      func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
      }

      func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return Images.placeholder
      }

      func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        // NOTHING
      }

      func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        // NOTHING
      }

      func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        // NOTHING
      }
    }

    private enum Images {
      static let defaultMissing = UIImage(systemName: "xmark.octagon.fill") ?? UIImage()
      static let placeholder = UIImage(systemName: "photo.fill") ?? UIImage()
    }
  }
}

extension HTMLView.AztecView.Coordinator: NSLayoutManagerDelegate {
  func layoutManager(
    _ layoutManager: NSLayoutManager,
    didCompleteLayoutFor textContainer: NSTextContainer?,
    atEnd layoutFinishedFlag: Bool
  ) {
    guard layoutFinishedFlag else { return }
    guard
      let container = layoutManager.textContainers.first,
      let textView = textView
    else {
      assertionFailure("Unexpected text container configuration")
      return
    }
    let containerHeight = ceil(layoutManager.usedRect(for: container).height) +
      textView.textContainerInset.top +
      textView.textContainerInset.bottom
    if containerHeight != view.desiredHeight {
      layoutLogger.debug("Changing height from \(view.desiredHeight) to \(containerHeight)")
      self.view.desiredHeight = containerHeight
    }
  }
}

private extension TextView {
  /// Prevents layoutManager delegate notifications from being sent as a consequence of actions performed in `block`
  func suppressLayoutNotifications(during block: () -> Void) {
    let existingDelegate = layoutManager.delegate
    layoutManager.delegate = nil
    block()
    layoutManager.delegate = existingDelegate
  }
}
