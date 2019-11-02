// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct CardAnswerButtonRow: View {
  let card: Card
  let didSelectAnswer: ((CardAnswer) -> Void)? = nil

  var body: some View {
    HStack {
      ForEach(eligibleAnswers, id: \.self) { answer in
        self.button(for: answer)
      }
    }
  }

  var eligibleAnswers: [CardAnswer] {
    switch card.type {
    case .new, .learning:
      return [.again, .good, .easy]
    case .due, .filtered:
      return [.again, .hard, .good, .easy]
    }
  }

  func button(for answer: CardAnswer) -> some View {
    Button(action: { self.didSelectAnswer?(answer) }) {
      Text(self.buttonLabel(for: answer))
        .foregroundColor(Color.white)
        .padding(.all)
    }
    .background(self.buttonColor(for: answer))
    .cornerRadius(10)
  }

  func buttonLabel(for answer: CardAnswer) -> String {
    switch answer {
    case .again:
      return "Again"
    case .easy:
      return "Easy"
    case .good:
      return "Good"
    case .hard:
      return "Hard"
    }
  }

  func buttonColor(for answer: CardAnswer) -> Color {
    switch answer {
    case .again:
      return .red
    case .hard:
      return .orange
    case .good:
      return .blue
    case .easy:
      return .green
    }
  }
}

struct CardAnswerButtonRow_Previews: PreviewProvider {
    static var previews: some View {
      CardAnswerButtonRow(card: Card.nileCard)
    }
}
