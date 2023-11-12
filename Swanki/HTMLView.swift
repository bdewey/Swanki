// Copyright © 2019-present Brian Dewey.

import Aztec
import os
import SwiftUI

private let layoutLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "org.brians-brain.HTMLView.layout")

struct HTMLView: View {
  struct KeyCommand {
    let input: String
    let modifierFlags: UIKeyModifierFlags
    let action: () -> Void
  }

  /// Editable initializer.
  init(
    title: String,
    html: Binding<String>,
    baseURL: URL?,
    backgroundColor: UIColor = .systemBackground,
    keyCommands: [KeyCommand] = [],
    shouldBeFirstResponder: Bool = false
  ) {
    self.title = title
    self._html = html
    self.baseURL = baseURL
    self.backgroundColor = backgroundColor
    self.keyCommands = keyCommands
    self.shouldBeFirstResponder = shouldBeFirstResponder

    self.isEditable = true
  }

  /// Non-editable initializer.
  init(
    title: String,
    html: String,
    baseURL: URL?,
    backgroundColor: UIColor = .systemBackground,
    keyCommands: [KeyCommand] = [],
    shouldBeFirstResponder: Bool = false
  ) {
    self.title = title
    self._html = .constant(html)
    self.baseURL = baseURL
    self.backgroundColor = backgroundColor
    self.keyCommands = keyCommands
    self.shouldBeFirstResponder = shouldBeFirstResponder

    self.isEditable = false
  }

  /// the view title -- will be its accessibility label.
  let title: String

  /// The HTML content to edit.
  @Binding var html: String

  /// The base URL from which to load images.
  let baseURL: URL?

  /// If we should allow content editing
  var isEditable: Bool = false

  /// Background color for the editor.
  var backgroundColor: UIColor = .systemBackground

  /// Key commands active in this view.
  let keyCommands: [KeyCommand]

  /// If true, we should make this view firstResponder if it isn't already.
  let shouldBeFirstResponder: Bool

  /// Holds the height of the view. Will adjust to the content size of the actual content.
  @State private var desiredHeight: CGFloat = 100

  var body: some View {
    logger.debug("Rendering HTMLView.body with desiredHeight = \(desiredHeight)")
    return AztecView(
      html: $html,
      baseURL: baseURL,
      isEditable: isEditable,
      backgroundColor: backgroundColor,
      keyCommands: keyCommands,
      shouldBeFirstResponder: shouldBeFirstResponder,
      desiredHeight: $desiredHeight
    )
    .frame(idealHeight: desiredHeight, maxHeight: desiredHeight)
    .accessibility(label: Text(verbatim: title))
  }
}

private extension HTMLView {
  /// Instantiates an Aztec HTML editor.
  /// Assumes that there is a CollectionDatabase in the environment.
  struct AztecView: UIViewRepresentable {
    /// The HTML content to edit.
    @Binding var html: String

    /// The base URL from which to load images.
    let baseURL: URL?

    /// If we should allow content editing
    let isEditable: Bool

    let backgroundColor: UIColor
    let keyCommands: [KeyCommand]
    let shouldBeFirstResponder: Bool

    @Binding var desiredHeight: CGFloat

    func makeUIView(context: UIViewRepresentableContext<AztecView>) -> KeybindingTextView {
      layoutLogger.debug("Making a new Aztec view")
      let textView = KeybindingTextView(
        defaultFont: UIFont.preferredFont(forTextStyle: .body),
        defaultMissingImage: Images.defaultMissing
      )
      context.coordinator.textView = textView
      return textView
    }

    func updateUIView(_ textView: KeybindingTextView, context: UIViewRepresentableContext<AztecView>) {
      context.coordinator.coordinatedHTMLUpdate(html)
      // Try to keep the bottom of the text in the viewport.
      // TODO: Should this be customizable behavior? What happens if the person starts
      // editing -- do they ever get tp see content that's scrolled off the top?
      // Needs experimentation.
      let overflowY = max(0, textView.contentSize.height - textView.bounds.maxY)
      if overflowY > 0 {
        layoutLogger.debug("Adjusting Y offset by \(overflowY) points (bounds max = \(textView.bounds.maxY), content height = \(textView.contentSize.height))")
        textView.contentOffset.y += overflowY
      }
      textView.isEditable = isEditable
      textView.backgroundColor = backgroundColor
      textView.customKeyCommands = keyCommands
      if shouldBeFirstResponder, !context.coordinator.isFirstResponder {
        textView.becomeFirstResponder()
      }
    }

    func makeCoordinator() -> Coordinator {
      layoutLogger.debug("Making a new coordinator")
      return Coordinator(self)
    }

    /// Coordinator object -- serves as our delegate.
    final class Coordinator: NSObject, TextViewAttachmentDelegate {
      /// The associated view.
      var view: AztecView

      var isFirstResponder = false

      /// The most recent raw HTML string set on `view`
      private var html: String?

      private var isSettingHTML = false

      func coordinatedHTMLUpdate(_ html: String) {
        guard html != self.html else { return }
        self.html = html
        isSettingHTML = true
        textView?.setHTML(html)
        isSettingHTML = false
      }

      /// Our associated Aztec TextVieiiw
      var textView: TextView! {
        willSet {
          assert(textView == nil)
        }
        didSet {
          textView.textAttachmentDelegate = self
          textView.delegate = self
          textView.layoutManager.delegate = self
        }
      }

      var deferredUpdateBlock: ((AztecView) -> Void)?

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
          let resolvedURL = URL(string: url.relativeString, relativeTo: view.baseURL)
        else {
          failure()
          return
        }
        DispatchQueue.global(qos: .default).async {
          let image = (try? Data(contentsOf: resolvedURL)).flatMap { UIImage(data: $0) }
          DispatchQueue.main.async {
            if let image {
              success(image)
              logger.debug("Finished loading image, size = \(String(describing: image.size), privacy: .public)")
            } else {
              failure()
            }
          }
        }
        failure()
      }

      func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        nil
      }

      func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        Images.placeholder
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

private extension HTMLView {
  final class KeybindingTextView: Aztec.TextView {
    var customKeyCommands: [KeyCommand] = []

    override var keyCommands: [UIKeyCommand]? {
      guard !customKeyCommands.isEmpty else {
        return super.keyCommands
      }
      return customKeyCommands.map {
        UIKeyCommand(input: $0.input, modifierFlags: $0.modifierFlags, action: #selector(handleCustomKeyCommand(command:)))
      }
    }

    @objc func handleCustomKeyCommand(command: UIKeyCommand) {
      for customCommand in customKeyCommands where command.input == customCommand.input && command.modifierFlags == customCommand.modifierFlags {
        customCommand.action()
      }
    }
  }
}

extension HTMLView.AztecView.Coordinator: UITextViewDelegate {
  // Need to explicitly look for text input that should be interpreted as commands instead to make
  // the software keyboard work.
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    guard let keybindingTextView = textView as? HTMLView.KeybindingTextView else {
      return true
    }
    if range.length == 0 {
      for keyCommand in keybindingTextView.customKeyCommands where keyCommand.input == text {
        keyCommand.action()
        return false
      }
    }
    return true
  }

  func textViewDidChange(_ textView: UITextView) {
    // When we're inside the updateView call, we're going to get this callback. We'll get infinite
    // updates if we modify the HTML here.
    guard !isSettingHTML, let htmlView = textView as? TextView else {
      return
    }
    let html = htmlView.getHTML()
    // Avoid update loops by remembering this HTML
    self.html = html
    view.html = html
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    isFirstResponder = true
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    isFirstResponder = false
  }
}

extension HTMLView.AztecView.Coordinator: NSLayoutManagerDelegate {
  private func setDesiredHeightLayoutUsedRect(_ layoutUsedRect: CGRect) {
    guard let textView else { return }
    let containerHeight = ceil(layoutUsedRect.height) +
      textView.textContainerInset.top +
      textView.textContainerInset.bottom
    view.desiredHeight = containerHeight
  }

  func layoutManager(
    _ layoutManager: NSLayoutManager,
    didCompleteLayoutFor textContainer: NSTextContainer?,
    atEnd layoutFinishedFlag: Bool
  ) {
    guard layoutFinishedFlag, let textContainer else { return }
    let layoutUsedRect = layoutManager.usedRect(for: textContainer)
    DispatchQueue.main.async { [weak self] in
      self?.setDesiredHeightLayoutUsedRect(layoutUsedRect)
    }
  }
}
