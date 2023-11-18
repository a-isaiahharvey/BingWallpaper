//
//  ContentView.swift
//  BingWallpaper
//
//  Created by Allister Isaiah Harvey on 08/11/2023.
//

import SwiftUI

struct ContentView: View {
  @State var todayButtonEnabled = true
  @State var todayButtonTitle = "Today"

  @State var previousDayButtonEnabled = false
  @State var previousDayString = String()

  @State var nextDayButtonEnabled = false
  @State var nextDayString = String()

  @State var timerTask = Timer()
  @State var wallpaperInfoUrlString = String()
  @State var wallpaperInfoString = String()
  @State var pictureManager = PictureManager()
  @State var dateText = String()

  var body: some View {
    HStack {
      VStack {
        Image(nsImage: NSImage(named: "AppIcon")!)
        Text("Bing Wallpaper").font( /*@START_MENU_TOKEN@*/.title /*@END_MENU_TOKEN@*/)

        HStack {
          Button(action: previousDay) {
            Label(previousDayString, systemImage: "arrow.left").labelStyle(.iconOnly)
          }.disabled(!self.previousDayButtonEnabled)
          Button(todayButtonTitle) {
            Task {
              try! await jumpToToday()
            }
          }.disabled(!self.todayButtonEnabled)
          Button(action: nextDay) {
            Label(nextDayString, systemImage: "arrow.right").labelStyle(.iconOnly)
          }.disabled(!self.nextDayButtonEnabled)
        }

        Text(self.dateText)
        if let wallpaperInfoStringURL = URL(string: self.wallpaperInfoUrlString) {
          Link(self.wallpaperInfoString, destination: wallpaperInfoStringURL).font(.subheadline)
        }

        Button("Quit") {
          quitApplication(sender: nil)
        }.buttonStyle(.bordered)
      }.padding()
    }
    .padding()
    .task {
      await self.downloadWallpapers()

      if let currentDate = Preferences.Shared.string(
        Preferences.Shared.Key.currentSelectedImageDate)
      {
        let _ = try! self.jumpTo(date: currentDate)
      } else {
        let _ = try! await self.jumpToToday()
      }
    }
  }

  func jumpTo(date: String) throws -> Bool {
    if let workingDirectory = Preferences.Shared.string(
      Preferences.Shared.Key.downloadImagesStoragePath),
      let region = Preferences.Shared.string(Preferences.Shared.Key.currentSelectedBingRegion)
    {
      if self.pictureManager.checkWallpaperExist(workingDirectory, on: date, in: region) {
        let info = try PictureManager.getWallpaperInfo(workingDirectory, on: date, in: region)
        let infoString = info.copyright.replacing([",", "(", ")"], with: "\n")

        self.wallpaperInfoString = infoString
        self.wallpaperInfoUrlString = info.copyrightLink

        self.dateText = date

        Preferences.Shared.set(
          with: date, default: Preferences.Shared.Key.currentSelectedImageDate)

        try self.pictureManager.setWallpaper(workingDirectory, on: date, at: region)

        let searchLimit = 365
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd"

        if let date = formatter.date(from: date) {
          self.previousDayButtonEnabled = false
          for index in 1...searchLimit {
            let timeInterval: TimeInterval = -3600.0 * 24.0 * Double(index)
            let anotherDay = date.addingTimeInterval(timeInterval)
            let anotherDayString = formatter.string(for: anotherDay)!

            if self.pictureManager.checkWallpaperExist(
              workingDirectory, on: anotherDayString, in: region)
            {
              self.previousDayString = anotherDayString
              self.previousDayButtonEnabled = true
              break
            }
          }
        }

        if let date = formatter.date(from: date) {
          self.nextDayButtonEnabled = false
          for index in 1...searchLimit {
            let timeInterval: TimeInterval = 3600.0 * 24.0 * Double(index)
            let anotherDay = date.addingTimeInterval(timeInterval)
            let anotherDayString = formatter.string(for: anotherDay)!
            if self.pictureManager.checkWallpaperExist(
              workingDirectory, on: anotherDayString, in: region)
            {
              self.nextDayString = anotherDayString
              self.nextDayButtonEnabled = true
              break
            }
          }
        }

        return true
      }
    }
    return false
  }

  func jumpToToday() async throws {
    self.todayButtonEnabled = false
    self.todayButtonTitle = "Fetching..."

    if let workingDirectory = Preferences.Shared.string(
      Preferences.Shared.Key.downloadImagesStoragePath),
      let currentRegion = Preferences.Shared.string(
        Preferences.Shared.Key.currentSelectedBingRegion)
    {

      try await self.pictureManager.fetchLastWallpaper(workingDirectory, at: currentRegion)
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    let ok = try self.jumpTo(date: formatter.string(from: Date()))

    if !ok {
      let _ = try self.jumpTo(
        date: formatter.string(for: Date().addingTimeInterval(-(3600.0 * 24.0)))!)
    }

    self.todayButtonEnabled = true
    self.todayButtonTitle = "Today"
  }

  func previousDay() {
    let _ = try! self.jumpTo(date: self.previousDayString)
  }

  func today() {
    let _ = try! self.jumpTo(date: self.previousDayString)
  }

  func nextDay() {
    let _ = try! self.jumpTo(date: self.nextDayString)
  }

  func wallpaperInfoButtonClicked() {
    NSWorkspace.shared.open(URL(string: Preferences.Shared.Key.downloadImagesStoragePath)!)
  }

  func downloadWallpapers() async {
    if let workingDirectory = Preferences.Shared
      .string(
        Preferences.Shared.Key.downloadImagesStoragePath),
      let region = Preferences.Shared
        .string(Preferences.Shared.Key.currentSelectedBingRegion)
    {

      let _ = try! await self.pictureManager.fetchWallpapers(workingDirectory, at: region)

    }

    if Preferences.Shared.bool(for: Preferences.Shared.Key.willAutoChangeWallpaper) {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let _ = try! self.jumpTo(date: formatter.string(from: Date()))
    }
  }

  func quitApplication(sender: Any?) {
    NSApplication.shared.terminate(sender)
  }
}

#Preview {
  ContentView()
}
