// Copyright © 2019-present Brian Dewey.

import SpacedRepetitionScheduler
import SwiftUI

struct CardAnswerButtonRow: View {
  let answers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)]
  var didSelectAnswer: ((CardAnswer) -> Void)?

  struct ButtonProperties: Hashable {
    let answer: CardAnswer
    let interval: TimeInterval
  }

  var body: some View {
    HStack {
      ForEach(buttonProperties, id: \.self) { properties in
        button(properties: properties)
      }
    }.frame(height: 100)
  }

  private var buttonProperties: [ButtonProperties] {
    answers.map {
      ButtonProperties(answer: $0.key, interval: $0.value.interval)
    }
  }

  func button(properties: ButtonProperties) -> some View {
    Button(action: { didSelectAnswer?(properties.answer) }) {
      Text(buttonLabel(properties: properties))
        .foregroundColor(Color.white)
        .padding(.all)
    }
    .background(buttonColor(for: properties.answer))
    .cornerRadius(10)
  }

  func buttonLabel(properties: ButtonProperties) -> String {
    let intervalString = DateComponentsFormatter.intervalFormatter.string(from: properties.interval)!
    return intervalString + "\n" + properties.answer.localizedName
  }

  func buttonColor(for answer: CardAnswer) -> Color {
    switch answer {
    case .again:
      .red
    case .hard:
      .orange
    case .good:
      .blue
    case .easy:
      .green
    }
  }
}

public extension DateComponentsFormatter {
  /// Shows the age of a page in a document list view.
  static let intervalFormatter: DateComponentsFormatter = {
    let ageFormatter = DateComponentsFormatter()
    ageFormatter.maximumUnitCount = 1
    ageFormatter.unitsStyle = .abbreviated
    ageFormatter.allowsFractionalUnits = false
    ageFormatter.allowedUnits = [.day, .hour, .minute]
    return ageFormatter
  }()
}

struct CardAnswerButtonRow_Previews: PreviewProvider {
  static var previews: some View {
    // Make some answers for a new item.
    let scheduler = SpacedRepetitionScheduler(learningIntervals: [.minute, 10 * .minute])
    return CardAnswerButtonRow(answers: scheduler.scheduleItem(SpacedRepetitionScheduler.Item()))
  }
}
