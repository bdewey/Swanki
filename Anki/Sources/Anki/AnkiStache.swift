// Copyright © 2019-present Brian Dewey.

import Foundation

/// Anki uses a modified variant of Mustache templates.
///
/// From anki/template/readme.anki:
///
/// > Behaviour is a little different from standard Mustache:
/// >
/// > - {{text}} returns text verbatim with no HTML escaping
/// > - {{{text}}} does the same and exists for backwards compatibility
/// > - partial rendering is disabled for security reasons
/// > - certain keywords like 'cloze' are treated specially

public struct AnkiTemplate {
  public init(template: String) {
    self.template = template
  }

  public let template: String

  public func render(_ context: Any? = nil) throws -> String {
    var result = Self.renderSections(template: template, context: context)
    result = Self.renderTags(template: result, context: context)
    return result
  }
}

private extension AnkiTemplate {
  enum Delimiter {
    static let opening = "{{"
    static let closing = "}}"
  }

  enum RegularExpression {
    private static let sectionPattern = #"\#(Delimiter.opening.quoted)([#|^])([^\}]*)\#(Delimiter.closing.quoted)(.+?)\#(Delimiter.opening.quoted)\/\2\#(Delimiter.closing.quoted)"#

    static let section =
      try! NSRegularExpression(
        pattern: sectionPattern,
        options: []
      )

    static let tag = try! NSRegularExpression(
      pattern: #"\#(Delimiter.opening.quoted)(#|=|&|!|>|\{)?(.+?)\1?\#(Delimiter.closing.quoted)"#,
      options: []
    )
  }

  private static func renderSections(template: String, context: Any?) -> String {
    var template = template
    while let result = RegularExpression.section.firstMatch(in: template, options: [], range: template.entireRange) {
      // If sectionRange or inner are nil, that's a programming error and not a template error.
      // Crash instead of throw.
      let sectionRange = Range(result.range(at: 0), in: template)!
      let shouldInvert = result.captureGroup(in: 1, text: template)! == "^"
      let sectionName = result.captureGroup(in: 2, text: template)!
      let inner = result.captureGroup(in: 3, text: template)!

      let replacement: String
      if shouldInvert != truthyFromContext(context, name: sectionName) {
        replacement = inner
      } else {
        replacement = ""
      }
      template.replaceSubrange(sectionRange, with: replacement)
    }
    return template
  }

  private static func renderTags(template: String, context: Any?) -> String {
    var template = template
    while let result = RegularExpression.tag.firstMatch(in: template, options: [], range: template.entireRange) {
      // If sectionRange or inner are nil, that's a programming error and not a template error.
      // Crash instead of throw.
      let sectionRange = Range(result.range(at: 0), in: template)!
      _ = result.captureGroup(in: 1, text: template)
      let tagName = result.captureGroup(in: 2, text: template)!

      let replacement = valueFromContext(context, name: tagName) ?? ""
      template.replaceSubrange(sectionRange, with: replacement)
    }
    return template
  }
}

private func valueFromContext(_ context: Any?, name: String) -> String? {
  if let dictionary = context as? [String: Any], let value = dictionary[name] {
    return String(describing: value)
  }
  return nil
}

private func truthyFromContext(_ context: Any?, name: String) -> Bool {
  if let dictionary = context as? [String: Any], let value = dictionary[name] as? Bool {
    return value
  }
  if let dictionary = context as? [String: Any] {
    return dictionary[name] != nil
  }
  return false
}

private extension String {
  var entireRange: NSRange {
    NSRange(startIndex..., in: self)
  }

  var quoted: String {
    let specialCharacters: [String] = [
      "\\",
      "*",
      "?",
      "+",
      "[",
      "(",
      ")",
      "{",
      "}",
      "^",
      "$",
      "|",
      ".",
      "/",
    ]
    var result = self
    for character in specialCharacters {
      result = result.replacingOccurrences(of: character, with: #"\\#(character)"#)
    }
    return result
  }
}

// MARK: - String helpers

// Copied from Aztec. Investigate getting rid of this.

private extension NSTextCheckingResult {
  /// Returns the match for the corresponding capture group position in a text
  ///
  /// - Parameters:
  ///   - position: the capture group position
  ///   - text: the string where the match was detected
  /// - Returns: the string with the captured group text
  ///
  func captureGroup(in position: Int, text: String) -> String? {
    guard position < numberOfRanges else {
      return nil
    }

    #if swift(>=4.0)
      let nsrange = range(at: position)
    #else
      let nsrange = rangeAt(position)
    #endif

    guard nsrange.location != NSNotFound else {
      return nil
    }

    let range = text.range(fromUTF16NSRange: nsrange)

    #if swift(>=4.0)
      let captureGroup = String(text[range])
    #else
      let captureGroup = text.substring(with: range)
    #endif

    return captureGroup
  }
}

private extension String {
  func range(fromUTF16NSRange utf16NSRange: NSRange) -> Range<String.Index> {
    let swiftUTF16Range = utf16.range(from: utf16NSRange)
    return range(from: swiftUTF16Range)
  }

  /// Converts a `Range<String.UTF16View.Index>` into a `Range<String.Index>` for this string.
  ///
  /// - Parameters:
  ///     - nsRange: the UTF16 NSRange to convert.
  ///
  /// - Returns: the requested `Range<String.Index>`
  ///
  func range(from utf16Range: Range<String.UTF16View.Index>) -> Range<String.Index> {
    let start = findValidLowerBound(for: utf16Range)
    let end = findValidUpperBound(for: utf16Range)

    return start ..< end
  }

  /// Converts the lower bound of a `Range<String.UTF16View.Index>` into a valid `String.Index` for this string.
  /// Won't allow out-of-range errors.
  ///
  /// - Parameters:
  ///     - for: the UTF16 range to convert.
  ///
  /// - Returns: A valid lower bound represented as a `String.Index`
  ///
  private func findValidLowerBound(for utf16Range: Range<String.UTF16View.Index>) -> String.Index {
    guard utf16.count >= utf16Range.lowerBound.utf16Offset(in: self) else {
      return String.UTF16View.Index(utf16Offset: 0, in: self)
    }

    return findValidBound(for: utf16Range.lowerBound, using: -)
  }

  /// Converts the upper bound of a `Range<String.UTF16View.Index>` into a valid `String.Index` for this string.
  /// Won't allow out-of-range errors.
  ///
  /// - Parameters:
  ///     - for: the UTF16 range to convert.
  ///
  /// - Returns: A valid upper bound represented as a `String.Index`
  ///
  private func findValidUpperBound(for utf16Range: Range<String.UTF16View.Index>) -> String.Index {
    guard utf16.count >= utf16Range.upperBound.utf16Offset(in: self) else {
      return String.Index(utf16Offset: utf16.count, in: self)
    }

    return findValidBound(for: utf16Range.upperBound, using: +)
  }

  /// Finds a valid UTF-8 `String.Index` matching the bound of a `String.UTF16View.Index`
  /// by adjusting the bound in a particular direction until it becomes valid.
  ///
  /// This is needed because some `String.UTF16View.Index` point to the middle of a UTF8
  /// grapheme cluster, which results in an invalid index, causing undefined behaviour.
  ///
  /// - Parameters:
  ///     - utf16Range: the UTF16View.Index to convert. Must be a valid index within the string.
  ///     - method: The method to use to move the bound – `+` or `-`
  ///
  /// - Returns: A corresponding `String.Index`
  ///
  private func findValidBound(for bound: String.UTF16View.Index, using method: (Int, Int) -> Int) -> String.Index {
    var newBound = bound.samePosition(in: self) // nil if we're inside a grapheme cluster
    var i = 1

    while newBound == nil {
      let newOffset = method(bound.utf16Offset(in: self), i)
      let newIndex = String.UTF16View.Index(utf16Offset: newOffset, in: self)
      newBound = newIndex.samePosition(in: self)
      i += 1
    }

    // We've verified aboe that this is a valid bound, so force upwrapping it is ok
    return newBound!
  }
}

private extension String.UTF16View {
  /// Converts a UTF16 `NSRange` into a `Range<String.UTF16View.Index>` for this string.
  ///
  /// - Parameters:
  ///     - nsRange: the UTF16 NSRange to convert.
  ///
  /// - Returns: the requested `Range<String.UTF16View.Index>` or `nil` if the conversion fails.
  ///
  func range(from nsRange: NSRange) -> Range<String.UTF16View.Index> {
    let start = index(startIndex, offsetBy: nsRange.location)
    let offset = count < nsRange.length ? count : nsRange.length
    let end = index(start, offsetBy: offset)

    return start ..< end
  }
}
