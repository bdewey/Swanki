// Copyright © 2019 Brian's Brain. All rights reserved.

import Logging
import SwiftUI
import UIKit

private let logger: Logger = {
  var logger = Logger(label: "org.brians-brain.Swanki")
  logger.logLevel = .debug
  return logger
}()


final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var collectionDatabase: CollectionDatabase?
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView().environmentObject(makeCollectionDatabase())

    // Use a UIHostingController as window root view controller.
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = UIHostingController(rootView: contentView)
      self.window = window
      window.makeKeyAndVisible()
    }
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
  }

  // MARK: - Private

  private func makeCollectionDatabase() -> CollectionDatabase {
    do {
      let homeDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let collectionDatabase = CollectionDatabase(url: homeDirectory)
      try collectionDatabase.emptyContainer()
      if let url = Bundle.main.url(forResource: "AncientHistory", withExtension: "apkg", subdirectory: "SampleData") {
        try collectionDatabase.importPackage(url)
      }
      try collectionDatabase.openDatabase()
      try collectionDatabase.fetchMetadata()
      try collectionDatabase.fetchNotes()
      let configs = try collectionDatabase.collectionMetadata?.loadDeckConfigs()
      logger.info("Loaded deck configs: \(configs)")
      return collectionDatabase
    } catch {
      fatalError("Could not create database: \(error)")
    }
  }
}
