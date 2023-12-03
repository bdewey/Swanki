# Changelog

## Unreleased

### Added

- XP! We track XP based upon how well you've studied your cards, and you can lose XP if you let cards 
  age beyond their due date. XP is shown on session start and session end to try to get **some** motivation
  going.
- Tips! I display a single tip right now telling you to rate how well you knew an answer.
- Deck progress chart! I show the number of cards in the new / learning / mastered state.

## [0.2.0] 2023-11-27

### Added

- Top-level "Study" menu command and toolbar item
- MacOS Sandbox entitlement for TestFlight capability

### Fixed

- Per-deck filtering of new/learing cards for study sessions
- Study sessions now look 10 minutes into the future to prevent learning gaps

## [0.1.0] 2023-11-25

This is the first version that I prepared for distribution (iOS TestFlight, MacOS direct distribution).
What exists here is a sufficient program to allow my son Patrick to study for his Spanish Lesson 2 work;
there's a whole lot that's hard-coded. It's not general-purpose at all.

I had one disappointing discovery when preparing this: `AVSpeechSynthesizer` doesn't work on iOS 17. I thought
this was just a simulator problem, but no -- according to Google searches, it's just broken and there's no
real workaround. (Some people say that some voices work, but I found no Spanish voice that does.) 
Hearing the words is an important part of language study, so for now my son will need to do this only on his
mac. I hope this is fixed in upcoming iOS releases.