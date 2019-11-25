// Copyright © 2019 Brian's Brain. All rights reserved.

import Mustache
import SwiftUI

struct CardView: View {
  struct Properties: Identifiable {
    var id: Int { card.id }
    let card: Card
    let answers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)]
    let model: NoteModel
    let note: Note
    let baseURL: URL?
  }

  let properties: Properties
  private(set) var didSelectAnswer: ((CardAnswer) -> Void)?

  @State private var side = Side.front

  var body: some View {
    VStack {
      WebView(htmlString: renderedSide, baseURL: properties.baseURL)
        .onTapGesture {
          self.flipToBack()
        }
      buttonRowOrEmpty
        .frame(height: 100.0)
    }
  }

  var buttonRowOrEmpty: some View {
    VStack {
      if side == .back {
        CardAnswerButtonRow(answers: properties.answers, didSelectAnswer: {
          self.side = Side.front
          self.didSelectAnswer?($0)
        })
      } else {
        /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
      }
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
    for field in properties.model.fields {
      data[field.name] = properties.note.fieldsArray[field.ord]
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
    let template = properties.model.templates[properties.card.templateIndex]
    switch side {
    case .front:
      return template.qfmt
    case .back:
      return template.afmt
    }
  }

  func flipToBack() {
    if side == .front {
      side = .back
    }
  }
}

struct CardView_Previews: PreviewProvider {
  static var previews: some View {
    let scheduler = SpacedRepetitionScheduler(learningIntervals: [.minute, 10 * .minute])
    return CardView(properties: CardView.Properties(
      card: Card.nileCard,
      answers: scheduler.scheduleItem(SpacedRepetitionScheduler.Item()),
      model: NoteModel.basic,
      note: Note.nileRiver,
      baseURL: nil
    ))
  }
}
