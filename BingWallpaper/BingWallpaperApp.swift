//
//  BingWallpaperApp.swift
//  BingWallpaper
//
//  Created by Allister Isaiah Harvey on 08/11/2023.
//

import SwiftUI

@main
struct BingWallpaperApp: App {
  var body: some Scene {
    MenuBarExtra {
      ContentView()
    } label: {
      Image("MenubarIcon")
    }.menuBarExtraStyle(.window)

    WindowGroup {

    }
  }
}
