import AppKit
import Foundation

public struct PictureManager {
    var netRequest: URLRequest
    var fileManager: FileManager
    var pastWallpaperRange: Int
    
    public init() {
        self.netRequest = URLRequest(url: URL(string: "http://www.bing.com/HpImageArchive.aspx")!)
        self.netRequest.cachePolicy = .useProtocolCachePolicy
        self.netRequest.timeoutInterval = 15.0
        self.netRequest.httpMethod = "GET"
        self.fileManager = FileManager.default
        self.pastWallpaperRange = 10
    }
    
    static func buildInfoPath(_ workingDirectory: String, on date: String, at region: String)
    -> String
    {
        if region.isEmpty {
            return "\(workingDirectory)/\(date).json"
        }
        
        return "\(workingDirectory)/\(date)_\(region).json"
    }
    
    static func buildImagePath(_ workingDirectory: String, on date: String, at region: String)
    -> String
    {
        if region.isEmpty {
            return "\(workingDirectory)/\(date).jpg"
        }
        
        return "\(workingDirectory)/\(date)_\(region).jpg"
    }
    
    func checkAndCreate(workingDirectory path: URL) throws {
        try self.fileManager.createDirectory(
            at: path, withIntermediateDirectories: true, attributes: nil)
    }
    
    mutating func obtainWallpaper(_ workingDirectory: String, at index: Int, at region: String) async throws
    {
        let baseURL = "http://www.bing.com/HpImageArchive.aspx"
        
        self.netRequest.url = URL(string: "\(baseURL)?format=js&n=1&idx=\(index)&cc=\(region)")
        
        let (responseData, _) = try await URLSession.shared.data(for: self.netRequest)
        
        let data =
        try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
        as! [String: Any]
        
        if let objects = data["images"] as? [[String: Any]] {
            if let startDateString = objects[0]["startdate"] as? String {
                let urlString = objects[0]["url"] as! String
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                
                if let startDate = formatter.date(from: startDateString) {
                    formatter.dateFormat = "yyyy-MM-dd"
                    let dateString = formatter.string(from: startDate)
                    
                    let infoPath = PictureManager.buildInfoPath(workingDirectory, on: dateString, at: region)
                    let imagePath = PictureManager.buildImagePath(
                        workingDirectory, on: dateString, at: region)
                                        
                    if !self.fileManager.fileExists(atPath: infoPath) {
                        let workingDirectory = URL(filePath: workingDirectory)
                        try self.checkAndCreate(workingDirectory: workingDirectory)
                        
                        try responseData.write(to: URL(filePath: infoPath), options: .atomic)
                    }
                    
                    if !self.fileManager.fileExists(atPath: imagePath) {
                        let workingDirectory = URL(filePath: workingDirectory)
                        try self.checkAndCreate(workingDirectory: workingDirectory)
                        
                        if urlString.contains("http://") || urlString.contains("https://") {
                            self.netRequest.url = URL(string: urlString)
                        } else {
                            self.netRequest.url = URL(string: "https://www.bing.com\(urlString)")
                        }
                        
                        let (imageResponseData, _) = try await URLSession.shared.data(for: self.netRequest)
                        
                        try imageResponseData.write(
                            to: URL(fileURLWithPath: imagePath), options: .atomic)
                    }
                }
            }
        }
    }
    
    public mutating func fetchWallpapers(_ workingDirectory: String, at region: String) async throws {
        for index in -1..<self.pastWallpaperRange {
            try await self.obtainWallpaper(workingDirectory, at: index, at: region)
        }
    }
    
    public mutating func fetchLastWallpaper(_ workingDirectory: String, at region: String) async throws {
        for index in -1..<self.pastWallpaperRange {
            try await self.obtainWallpaper(workingDirectory, at: index, at: region)
        }
    }
    
    public mutating func checkWallpaperExist(
        _ workingDirectory: String, on date: String, at region: String
    ) -> Bool {
        self.fileManager.fileExists(
            atPath: PictureManager.buildImagePath(workingDirectory, on: date, at: region))
    }
    
    public static func getWallpaperInfo(
        _ workingDirectory: String, on date: String, at region: String
    ) throws -> (copyright: String, copyrightLink: String) {
        let jsonString = try String(
            contentsOfFile: self.buildInfoPath(workingDirectory, on: date, at: region),
            encoding: .utf8)
        
        if let jsonData = jsonString.data(using: .utf8) {
            let data =
            try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            as! [String: Any]
            
            if let objects = data["images"] as? [[String: Any]] {
                if let copyrightString = objects[0]["copyright"] as? String {
                    let copyrightLinkString = objects[0]["copyrightlink"] as! String
                    
                    return (copyrightString, copyrightLinkString)
                }
            }
        }
        
        return (String(), String())
    }
    
    public mutating func setWallpaper(_ workingDirectory: String, on date: String, at region: String)
    throws
    {
        if self.checkWallpaperExist(workingDirectory, on: date, at: region) {
            for screen in NSScreen.screens {
                try NSWorkspace.shared.setDesktopImageURL(
                    NSURL(
                        fileURLWithPath: PictureManager.buildImagePath(workingDirectory, on: date, at: region))
                    as URL,
                    for: screen, options: [:])
            }
        }
    }
}
