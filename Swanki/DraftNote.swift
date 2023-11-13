// Copyright © 2019-present Brian Dewey.

import Anki
import Foundation
import SwiftUI

/// Wraps a Note and provides bindings to its individual fields.
@dynamicMemberLookup
public final class DraftNote: ObservableObject, Identifiable {
  public init(
    title: LocalizedStringKey,
    note: Anki.Note,
    noteModel: NoteModel,
    commitAction: @escaping (Anki.Note) -> Void
  ) {
    self.title = title
    self.note = note
    self.noteModel = noteModel
    self.commitAction = commitAction
  }

  public let title: LocalizedStringKey
  @Published public var note: Anki.Note
  public let noteModel: NoteModel
  public let commitAction: (Anki.Note) -> Void

  public var id: Int { note.id }

  /// The number of card templates that are currently valid for this note.
  public var completeCardCount: Int {
    let validTemplates = noteModel.templates.filter { template in
      guard let templateRequirements = noteModel.requirements?.first(where: { $0.templateId == template.ord }) else {
        // If there are no special requirements, assume this template is valid for anything.
        logger.debug("No requirements for \(template.ord), assuming valid")
        return true
      }
      switch templateRequirements.requirementType {
      case .none:
        return false
      case .any:
        for fieldIndex in templateRequirements.fields {
          if !note.fieldsArray[fieldIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
          }
        }
        return false
      case .all:
        for fieldIndex in templateRequirements.fields {
          if note.fieldsArray[fieldIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
          }
        }
        return true
      }
    }
    return validTemplates.count
  }

  public func field(at index: Int) -> Binding<String> {
    Binding<String>(
      get: { self.note.fieldsArray[index] },
      set: { self.note.setField(at: index, to: $0) }
    )
  }

  /// Allow read-only access to all of the wrapped `note` properties.
  public subscript<T>(dynamicMember keyPath: KeyPath<Anki.Note, T>) -> T {
    note[keyPath: keyPath]
  }
}
