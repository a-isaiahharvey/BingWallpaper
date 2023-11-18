import Foundation

public struct Preferences {
  public struct Region {
    public static let all = [
      "Argentina": "AR",
      "Australia": "AU",
      "Austria": "AT",
      "Belgium": "BE",
      "Brazil": "BR",
      "Canada": "CA",
      "Chile": "CL",
      "Denmark": "DK",
      "Finland": "FI",
      "France": "FR",
      "Germany": "DE",
      "Hong Kong SAR": "HK",
      "India": "IN",
      "Indonesia": "ID",
      "Italy": "IT",
      "Japan": "JP",
      "Korea": "KR",
      "Malaysia": "MY",
      "Mexico": "MX",
      "Netherlands": "NL",
      "New Zealand": "NZ",
      "Norway": "NO",
      "China": "CN",
      "Poland": "PL",
      "Portugal": "PT",
      "Philippines": "PH",
      "Russia": "RU",
      "Saudi Arabia": "SA",
      "South Africa": "ZA",
      "Spain": "ES",
      "Sweden": "SE",
      "Switzerland": "CH",
      "Taiwan": "TW",
      "Turkey": "TR",
      "United Kingdom": "GB",
      "United States": "US",
    ]
  }

  public struct Shared {
    static let defaults = [
      Key.downloadImagesStoragePath: "\(NSHomeDirectory())/Pictures/Bing Wallpaper",
      Key.currentSelectedBingRegion: Preferences.Region.all["United States"]!,
    ]

    public enum Key {
      static let willLaunchOnSystemStartup = "WillLaunchOnSystemStartup"

      static let willDisplayIconInDock = "WillDisplayIconInDock"

      static let willAutoDownloadNewImages = "WillAutoDownloadNewImages"

      static let willAutoChangeWallpaper = "WillAutoChangeWallpaper"

      static let downloadImagesStoragePath = "DownloadedImagesStoragePath"

      static let currentSelectedBingRegion = "CurrentSelectedBingRegion"

      static let currentSelectedImageDate = "CurrentSelectedImageDate"
    }

    public static func bool(for key: String) -> Bool {
      UserDefaults.standard.bool(forKey: key)
    }

    public static func boolAsInt(for key: String) -> Int {
      if bool(for: key) {
        1
      } else {
        0
      }
    }

    public static func set(_ value: Bool, defaultName: String) {
      UserDefaults.standard.set(value, forKey: defaultName)
    }

    public static func set(with string: String, default name: String) {
      UserDefaults.standard.set(string, forKey: name)
    }

    public static func string(_ key: String) -> String? {
      if let value = UserDefaults.standard.string(forKey: key) {
        return value
      } else {
        let string =
          switch defaults[key] {
          case .none:
            defaults[key]
          case .some(let value):
            value
          }

        return string
      }
    }

    public static func clear() {
      for key in UserDefaults.standard.dictionaryRepresentation().keys {
        UserDefaults.standard.removeObject(forKey: key)
      }
    }
  }
}
