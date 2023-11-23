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
    let shortcut: String
  }

  var body: some View {
    HStack {
      ForEach(buttonProperties, id: \.self) { properties in
        VStack {
          button(properties: properties)
          Text(properties.shortcut)
            .foregroundColor(.secondary)
        }
      }
    }.frame(height: 100)
  }

  private var buttonProperties: [ButtonProperties] {
    answers.enumerated().map { index, tuple in
      ButtonProperties(
        answer: tuple.key,
        item: tuple.value,
        interval: tuple.value.interval,
        shortcut: String(index + 1)
      )
    }
  }

  private func button(properties: ButtonProperties) -> some View {
    Button(action: { didSelectAnswer?(properties.answer, properties.item) }) {
      VStack {
        Text(properties.answer.localizedName)
        Text(DateComponentsFormatter.intervalFormatter.string(from: properties.interval)!)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.all)
    }
    .buttonStyle(.plain)
    .background(buttonColor(for: properties.answer).opacity(0.4))
    .cornerRadius(10)
    .keyboardShortcut(KeyEquivalent(properties.shortcut.first!), modifiers: [])
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
