//
//  ContentView.swift
//  BingWallpaper
//
//  Created by Allister Isaiah Harvey on 08/11/2023.
//

import SwiftUI

struct ContentView: View {
    @State var timerTask = Timer()
    @State var previousDateString = String()
    @State var nextDateString = String()
    @State var wallpaperInfoUrlString = String()
    @State var wallpaperInfoString = String()
    @State var pictureManager = PictureManager()
    @State var dateText = String()
    
    var body: some View {
        HStack {
            VStack {
                Image(nsImage: NSImage(named: "AppIcon")!)
                Text("Bing Wallpaper").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                
                HStack {
                    Button(action: previousDay) {
                        Label(previousDateString, systemImage: "arrow.left").labelStyle(.iconOnly)
                    }
                    Button("Today") {
                        
                    }.task {
                        try! await jumpToToday()
                    }
                    Button(action: nextDay) {
                        Label(nextDateString, systemImage: "arrow.right").labelStyle(.iconOnly)
                    }
                }
                Text(self.dateText)
                if let wallpaperInfoStringURL = URL(string: self.wallpaperInfoUrlString) {
                    Link(self.wallpaperInfoString, destination: wallpaperInfoStringURL)
                }
                
                Button("Quit") {
                    quitApplication(sender: nil)
                }.buttonStyle(.bordered)
            }.padding()
        }
        .padding()
        .task {
            await self.downloadWallpapers()
            
            if let currentDate = Preferences.Shared.string(Preferences.Shared.Key.currentSelectedImageDate) {
                let _ = try! self.jumpTo(date: currentDate)
            } else {
                let _ = try! await self.jumpToToday()
            }
        }
    }
    
    func jumpTo(date: String) throws -> Bool {
        if let workingDirectory = Preferences.Shared.string(
            Preferences.Shared.Key.downloadImagesStoragePath)
        {
            if let region = Preferences.Shared.string(Preferences.Shared.Key.currentSelectedBingRegion) {
                if self.pictureManager.checkWallpaperExist(workingDirectory, on: date, at: region) {
                    let info = try PictureManager.getWallpaperInfo(workingDirectory, on: date, at: region)
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
                        
                        for index in 1..<searchLimit {
                            let timeInterval: TimeInterval = -3600.0 * 24.0 * Double(index)
                            let anotherDay = date.addingTimeInterval(timeInterval)
                            let anotherDayString = formatter.string(for: anotherDay)!
                            
                            if self.pictureManager.checkWallpaperExist(
                                workingDirectory, on: anotherDayString, at: region)
                            {
                                self.previousDateString = anotherDayString
                                
                                break
                            }
                        }
                    }
                    
                    if let date = formatter.date(from: date) {
                        
                        for index in 1..<searchLimit {
                            let timeInterval: TimeInterval = 3600.0 * 24.0 * Double(index)
                            let anotherDay = date.addingTimeInterval(timeInterval)
                            let anotherDayString = formatter.string(for: anotherDay)!
                            if self.pictureManager.checkWallpaperExist(
                                workingDirectory, on: anotherDayString, at: region)
                            {
                                self.nextDateString = anotherDayString
                                break
                            }
                        }
                    }
                    return true
                }
            }
        }
        return false
        }
    
    func jumpToToday() async throws {
        if let workingDirectory = Preferences.Shared.string(
            Preferences.Shared.Key.downloadImagesStoragePath)
        {
            if let currentRegion = Preferences.Shared.string(
                Preferences.Shared.Key.currentSelectedBingRegion)
            {
                try await self.pictureManager.fetchLastWallpaper(workingDirectory, at: currentRegion)
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let ok = try self.jumpTo(date: formatter.string(from: Date()))
        
        if !ok {
            let _ = try self.jumpTo(
                date: formatter.string(for: Date().addingTimeInterval(-(3600.0 * 24.0)))!)
        }
    }
    
    func previousDay() {
        let _ = try! self.jumpTo(date: self.previousDateString)
    }
    
    func today() {
        let _ = try! self.jumpTo(date: self.previousDateString)
    }
    
    func nextDay() {
        let _ = try! self.jumpTo(date: self.nextDateString)
    }
    
    func wallpaperInfoButtonClicked() {
        NSWorkspace.shared.open(URL(string: Preferences.Shared.Key.downloadImagesStoragePath)!)
    }
    
    func downloadWallpapers() async {
        if let workingDirectory = Preferences.Shared
            .string(
                Preferences.Shared.Key.downloadImagesStoragePath)
        {
            if let region = Preferences.Shared
                .string(Preferences.Shared.Key.currentSelectedBingRegion)
            {
                let _ = try! await self.pictureManager.fetchWallpapers(workingDirectory, at: region)
            }
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
