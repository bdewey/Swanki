// Copyright © 2019 Brian's Brain. All rights reserved.

import Aztec
import SwiftUI

struct HtmlEditorView: UIViewRepresentable {
  let html: String

  func makeUIView(context: UIViewRepresentableContext<HtmlEditorView>) -> Aztec.TextView {
    let textView = TextView(
      defaultFont: UIFont.preferredFont(forTextStyle: .body),
      defaultMissingImage: Images.defaultMissing
    )
    textView.textAttachmentDelegate = context.coordinator
    return textView
  }

  func updateUIView(_ uiView: TextView, context: UIViewRepresentableContext<HtmlEditorView>) {
    uiView.setHTML(html)
    print("\(uiView.contentSize)")
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  final class Coordinator: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
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
