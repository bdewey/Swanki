// Copyright © 2019-present Brian Dewey.

import AVFoundation
import Foundation
import SpacedRepetitionScheduler
import SwiftData
import SwiftUI

/// Quizzes a learner on the contents of a specific card.
struct CardQuizView: View {
  /// The card to quiz.
  var card: Card

  /// A closure invoked when the learner selects an answer.
  var didSelectAnswer: ((CardAnswer, SpacedRepetitionScheduler.Item, TimeInterval) -> Void)?

  @State private var viewDidAppearTime: Date?
  @State private var isShowingBack = false

  var body: some View {
    VStack {
      Spacer()
      GenericCardView(card: card, cardSide: .front)
      if isShowingBack {
        Divider()
        GenericCardView(card: card, cardSide: .back)
      } else {
        Button("Reveal Answer", systemImage: "arrow.uturn.left") {
          withAnimation {
            isShowingBack = true
          }
        }
        .keyboardShortcut(" ", modifiers: [])
      }
      Spacer()
      if let exampleSentence = card.note?.exampleSentence,
         let attributedSentence = try? AttributedString(markdown: exampleSentence),
         !exampleSentence.isEmpty
      {
        HStack {
          VStack(alignment: .leading) {
            Text(attributedSentence)
              .font(.caption)
            if let english = card.note?.exampleSentenceEnglish, !english.isEmpty {
              Text(english)
                .font(.caption.italic())
            }
          }
          .foregroundColor(.secondary)
          Button("Speak", systemImage: "speaker.wave.2") {
            speakSampleSentence()
          }
          .labelStyle(.iconOnly)
        }
        .hidden(!isShowingBack)
      }
      CardAnswerButtonRow(answers: possibleAnswers) { answer, item in
        let duration = viewDidAppearTime.flatMap { Date.now.timeIntervalSince($0) } ?? 2
        didSelectAnswer?(answer, item, duration)
      }
      .hidden(!isShowingBack)
    }
    .onTapGesture {
      withAnimation {
        isShowingBack = true
      }
    }
    .onChange(of: isShowingBack, initial: false) {
      if isShowingBack {
        speakSampleSentence(delay: 0.2)
      }
    }
    .onAppear {
      viewDidAppearTime = .now
    }
    .onChange(of: card.id) {
      withAnimation {
        isShowingBack = false
      }
    }
  }

  private func speakSampleSentence(delay: TimeInterval = 0.0) {
    guard let exampleSentence = card.note?.exampleSentence,
          let attributedSentence = try? NSAttributedString(markdown: exampleSentence)
    else {
      return
    }
    let utterance = AVSpeechUtterance(attributedString: attributedSentence)
    utterance.voice = .init(language: "es")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.6
    utterance.preUtteranceDelay = delay
    AVSpeechSynthesizer.shared.speak(utterance)
  }

  private var possibleAnswers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)] {
    SpacedRepetitionScheduler.builtin.scheduleItem(.init(card))
  }
}

private struct ConditionalHidden: ViewModifier {
  let isHidden: Bool

  func body(content: Content) -> some View {
    if isHidden {
      content.hidden()
    } else {
      content
    }
  }
}

extension View {
  func hidden(_ shouldHide: Bool) -> some View {
    modifier(ConditionalHidden(isHidden: shouldHide))
  }
}

private struct SelectCardView: View {
  @Query var cards: [Card]

  var body: some View {
    if cards.count > 0 {
      CardQuizView(card: cards[0])
    }
  }
}

#Preview {
  SelectCardView()
    .frame(width: 400, height: 300)
    .modelContainer(.previews)
}
