// Copyright © 2019-present Brian Dewey.

import AVFoundation
import Foundation
import os

private extension Logger {
  static let speech = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "speech")
}

extension AVSpeechSynthesizer {
  static let shared = AVSpeechSynthesizer()
}

final class SwankiSpeechController: NSObject, AVSpeechSynthesizerDelegate {
  static let shared = SwankiSpeechController()

  public lazy var speechSynthesizer: AVSpeechSynthesizer = {
    let synthesizer = AVSpeechSynthesizer()
    synthesizer.delegate = self
    return synthesizer
  }()

  public let voice: AVSpeechSynthesisVoice? = {
    Logger.speech.debug("Available voices = \(AVSpeechSynthesisVoice.speechVoices().map(\.identifier).joined(separator: ", "))")
    guard let voice = AVSpeechSynthesisVoice(language: "es") else {
      Logger.speech.error("Could not create voice for language 'es")
      return nil
    }
    Logger.speech.info("Created voice: \(voice.identifier)")
    return voice
  }()

  public func speakVocabulary(from note: Note, delay: TimeInterval = 0, rate: Float = 1) {
    guard let front = note.front else {
      return
    }
    let utterance = AVSpeechUtterance(string: front)
    utterance.voice = voice
    utterance.preUtteranceDelay = delay
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
    speechSynthesizer.speak(utterance)
  }

  public func speakExampleSentence(from note: Note, delay: TimeInterval = 0, rate: Float = 1) {
    guard let sentence = note.exampleSentence, let attributedString = try? NSAttributedString(markdown: sentence) else {
      return
    }
    let utterance = AVSpeechUtterance(attributedString: attributedString)
    utterance.voice = voice
    utterance.preUtteranceDelay = delay
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
    speechSynthesizer.speak(utterance)
  }
}
