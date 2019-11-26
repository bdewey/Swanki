// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import SwiftUI

/// Wraps a Note and provides bindings to its individual fields.
@dynamicMemberLookup
public final class BindableNote: ObservableObject, Identifiable {
  public init(_ note: Note) {
    self.note = note
  }

  @Published public var note: Note

  public var id: Int { note.id }

  public func field(at index: Int) -> Binding<String> {
    return Binding<String>(
      get: { self.note.fieldsArray[index] },
      set: { self.note.setField(at: index, to: $0) }
    )
  }

  /// Allow read-only access to all of the wrapped `note` properties.
  public subscript<T>(dynamicMember keyPath: KeyPath<Note, T>) -> T {
    note[keyPath: keyPath]
  }
}
