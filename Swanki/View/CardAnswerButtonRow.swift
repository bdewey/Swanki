// Copyright © 2019-present Brian Dewey.

import SpacedRepetitionScheduler
import SwiftUI

/// Displays a row of answers that someone can select to pick scheduling of a new item.
struct CardAnswerButtonRow: View {
  /// The answers to choose from, and the corresponding ``SpacedRepetitionScheduler/Item`` values that will be selected if you pick the corresponding answer.
  let answers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)]

  /// A closure that is invoked with the selected answer and item.
  var didSelectAnswer: ((CardAnswer, SpacedRepetitionScheduler.Item) -> Void)?

  private struct ButtonProperties: Hashable {
    let answer: CardAnswer
    let item: SpacedRepetitionScheduler.Item
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
      ButtonProperties(answer: $0.key, item: $0.value, interval: $0.value.interval)
    }
  }

  private func button(properties: ButtonProperties) -> some View {
    Button(action: { didSelectAnswer?(properties.answer, properties.item) }) {
      Text(buttonLabel(properties: properties))
        .foregroundColor(Color.white)
        .padding(.all)
    }
    .buttonStyle(.plain)
    .background(buttonColor(for: properties.answer))
    .cornerRadius(10)
  }

  private func buttonLabel(properties: ButtonProperties) -> String {
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

private extension DateComponentsFormatter {
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

#Preview {
  // Make some answers for a new item.
  let scheduler = SpacedRepetitionScheduler(learningIntervals: [.minute, 10 * .minute])
  return CardAnswerButtonRow(answers: scheduler.scheduleItem(SpacedRepetitionScheduler.Item()))
}
