// Copyright © 2019 Brian's Brain. All rights reserved.

import Aztec
import SwiftUI

/// Instantiates an Aztec HTML editor.
/// Assumes that there is a CollectionDatabase in the environment.
struct HtmlEditorView: UIViewRepresentable {
  /// The HTML content to edit.
  // TODO: Turn this into a binding!
  let html: String

  /// The base URL from which to load images.
  let baseURL: URL

  @Binding var desiredHeight: CGFloat

  func makeUIView(context: UIViewRepresentableContext<HtmlEditorView>) -> Aztec.TextView {
    let textView = TextView(
      defaultFont: UIFont.preferredFont(forTextStyle: .body),
      defaultMissingImage: Images.defaultMissing
    )
    textView.textAttachmentDelegate = context.coordinator
    textView.delegate = context.coordinator
    textView.setHTML(html)
//    textView.isEditable = false
    return textView
  }

  func updateUIView(_ uiView: TextView, context: UIViewRepresentableContext<HtmlEditorView>) {

  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(self)
  }

  /// Coordinator object -- serves as our delegate.
  final class Coordinator: NSObject, TextViewAttachmentDelegate {
    /// The associated view.
    var view: HtmlEditorView

    init(_ view: HtmlEditorView) {
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
        let image = (try? Data(contentsOf: resolvedURL)).flatMap({ UIImage(data: $0) })
        DispatchQueue.main.async {
          if let image = image {
            success(image)
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
    static let defaultMissing = UIImage.init(systemName: "xmark.octagon.fill") ?? UIImage()
    static let placeholder = UIImage.init(systemName: "photo.fill") ?? UIImage()
  }
}

extension HtmlEditorView.Coordinator: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    DispatchQueue.main.async {
      print("Setting desired height to \(textView.contentSize.height)")
      self.view.desiredHeight = textView.contentSize.height
    }
  }
}
