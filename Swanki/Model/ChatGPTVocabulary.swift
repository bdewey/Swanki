// Copyright © 2019-present Brian Dewey.

import Foundation

/// The JSON format that ChatGPT uses for providing vocabulary for studying.
public struct ChatGPTVocabulary: Codable {
  public struct VocabularyItem: Codable {
    public var spanish: String
    public var english: String
    public var exampleSentenceSpanish: String
    public var exampleSentenceEnglish: String

    public enum CodingKeys: String, CodingKey {
      case spanish
      case english
      case exampleSentenceSpanish = "example_sentence_spanish"
      case exampleSentenceEnglish = "example_sentence_english"
    }
  }

  public var vocabulary: [VocabularyItem] = []
}
