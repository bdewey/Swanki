// Copyright © 2019-present Brian Dewey.

import AVFoundation
import Foundation

/// Keys used for Spanish study.
extension Note.Key {
  static let front: Note.Key = "front"
  static let back: Note.Key = "back"
  static let exampleSentenceSpanish: Note.Key = "exampleSentenceSpanish"
  static let exampleSentenceEnglish: Note.Key = "exampleSentenceEnglish"
}

extension Note {
  var front: String? {
    get {
      self[.front]
    }
    set {
      self[.front] = newValue
    }
  }

  var back: String? {
    get {
      self[.back]
    }
    set {
      self[.back] = newValue
    }
  }

  var exampleSentence: String? {
    get {
      self[.exampleSentenceSpanish]?
        .replacingOccurrences(of: "{{", with: "**")
        .replacingOccurrences(of: "}}", with: "**")
    }
    set {
      self[.exampleSentenceSpanish] = newValue
    }
  }

  var exampleSentenceEnglish: String? {
    get {
      self[.exampleSentenceEnglish]
    }
    set {
      self[.exampleSentenceEnglish] = newValue
    }
  }

  func speakSpanish() {
    guard let front else {
      return
    }
    let utterance = AVSpeechUtterance(string: front)
    utterance.voice = .init(language: "es")
    AVSpeechSynthesizer.shared.speak(utterance)
  }
}
