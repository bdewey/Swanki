// Copyright © 2019 Brian's Brain. All rights reserved.

import Mustache
import SwiftUI

struct CardView: View {
  let card: Card
  let model: NoteModel
  let note: Note
  @State private var side = Side.front

  var body: some View {
    Text(renderedSide)
      .onTapGesture {
        self.toggleSide()
    }
  }

  var renderedSide: String {
    do {
      return try text(for: side)
    } catch {
      logger.error("Unexpected error rendering card: \(error)")
      return "Error"
    }
  }
}

private extension CardView {
  /// The two sides of a card
  enum Side {
    /// The card front -- initially shown
    case front
    /// The card back -- shown after a recall attempt
    case back
  }

  func text(for side: Side) throws -> String {
    let template = try Template(string: mustacheTemplate(for: side))
    var data = [String: Any]()
    for field in model.fields {
      data[field.name] = note.fieldsArray[field.ord]
    }
    if side == .back {
      data["FrontSide"] = try Template(string: mustacheTemplate(for: .front)).render(data)
    }
    return try template.render(data)
  }

  static let initializeMustache: Void = {
    Mustache.DefaultConfiguration.contentType = .text
  }()

  func mustacheTemplate(for side: Side) -> String {
    _ = CardView.initializeMustache
    let template = model.templates[card.templateIndex]
    switch side {
    case .front:
      return template.qfmt
    case .back:
      return template.afmt
    }
  }

  func toggleSide() {
    switch side {
    case .front:
      side = .back
    case .back:
      side = .front
    }
  }
}

struct CardView_Previews: PreviewProvider {
  static var previews: some View {
    CardView(
      card: Card.nileCard,
      model: NoteModel.basic,
      note: Note.nileRiver
    )
  }
}
