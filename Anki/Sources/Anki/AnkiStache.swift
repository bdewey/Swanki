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
  static let sectionRegex = #/\{\{([#^])([^}]*)\}\}([\s\S]+?)\{\{\/\2\}\}/#
  static let tagRegex = #/\{\{\{(.+?)\}\}\}|\{\{([#=&!>])?(.+?)\}\}/#

  private static func renderSections(template: String, context: Any?) -> String {
    var template = template
    while let match = template.firstMatch(of: sectionRegex) {
      let shouldInvert = String(match.output.1) == "^"
      let sectionName = String(match.output.2)
      let inner = String(match.output.3)

      let replacement: String
      if shouldInvert != truthyFromContext(context, name: sectionName) {
        replacement = inner
      } else {
        replacement = ""
      }

      template.replaceSubrange(match.range, with: replacement)
    }
    return template
  }

  private static func renderTags(template: String, context: Any?) -> String {
    var template = template
    while let match = template.firstMatch(of: tagRegex) {
      let tagName = String(match.output.1 ?? match.output.3 ?? "")
      let replacement = valueFromContext(context, name: tagName) ?? ""
      template.replaceSubrange(match.range, with: replacement)
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
