// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

private extension CardAnswer {
  var correctish: Bool {
    switch self {
    case .again, .hard:
      return false
    case .good, .easy:
      return true
    }
  }
}

private struct ZIndexViewModifier: ViewModifier {
  let zIndex: Double

  func body(content: Content) -> some View {
    content.zIndex(zIndex)
  }
}

private extension AnyTransition {
  static func zIndex(_ zIndex: Double) -> AnyTransition {
    AnyTransition.modifier(
      active: ZIndexViewModifier(zIndex: 0),
      identity: ZIndexViewModifier(zIndex: zIndex)
    )
  }

  static func cardTransition(answer: CardAnswer?) -> AnyTransition {
    .asymmetric(
      insertion: .opacity,
      removal: AnyTransition
        .move(edge: (answer?.correctish ?? false) ? .trailing : .leading)
        .combined(with: .zIndex(1000))
    )
  }
}

struct CardView: View {
  struct Properties: Identifiable {
    var id: Int { card.id }
    let card: Card
    let stackIndex: Int
    let answers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)]
    let model: NoteModel
    let note: Note
    let baseURL: URL?
  }

  let properties: Properties
  private(set) var didSelectAnswer: ((CardAnswer, TimeInterval) -> Void)?

  @State private var side = Side.front
  @State private var showedFront: CFTimeInterval = 0
  @State private var answer: CardAnswer?

  var body: some View {
    VStack {
      HTMLView(title: "quiz", html: self.renderedSide, baseURL: self.properties.baseURL, backgroundColor: .secondarySystemBackground)
        .opacity(self.properties.stackIndex == 0 ? 1 : 0)
      self.buttonRowOrEmpty
        .layoutPriority(1)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        self.flipToBack()
      }
    }
    .onAppear {
      self.showedFront = CACurrentMediaTime()
    }
    .padding(.all)
    .background(
      ZStack {
        RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground))
        RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 1)
      }
    )
    .padding(.all)
    .transition(.cardTransition(answer: self.answer))
  }

  var buttonRowOrEmpty: some View {
    VStack {
      if side == .back {
        CardAnswerButtonRow(answers: properties.answers, didSelectAnswer: {
          self.answer = $0
          self.didSelectAnswer?($0, CACurrentMediaTime() - self.showedFront)
        }).transition(AnyTransition.opacity.combined(with: .scale(scale: 0.01, anchor: .top)))
      } else {
        /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
      }
    }
  }

  var renderedSide: String {
    if properties.stackIndex > 0 {
      return "\n"
    }
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
    let template = AnkiTemplate(template: mustacheTemplate(for: side))
    var data = [String: Any]()
    for field in properties.model.fields {
      data[field.name] = properties.note.fieldsArray[field.ord]
    }
    if side == .back {
      data["FrontSide"] = try AnkiTemplate(template: mustacheTemplate(for: .front)).render(data)
    }
    return try template.render(data)
  }

  func mustacheTemplate(for side: Side) -> String {
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
      stackIndex: 0,
      answers: scheduler.scheduleItem(SpacedRepetitionScheduler.Item()),
      model: NoteModel.basic,
      note: Note.nileRiver,
      baseURL: nil
    ))
  }
}
