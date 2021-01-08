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
