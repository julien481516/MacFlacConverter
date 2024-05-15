//
//  FileImported.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 13/05/2024.
//

import Foundation

struct FileImported: Identifiable, Hashable, Comparable {
    let id = UUID()
    let fileURL: URL
    var audioFileInfo: AudioFileInfo?
    
    var fileName: String {
        let fileNameWithExtension = fileURL.lastPathComponent.removingPercentEncoding ?? ""
        return (fileNameWithExtension as NSString).deletingPathExtension
    }
    
    static func < (lhs: FileImported, rhs: FileImported) -> Bool {
        lhs.fileName < rhs.fileName
    }
    
    static func == (lhs: FileImported, rhs: FileImported) -> Bool {
        lhs.fileURL == rhs.fileURL
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fileURL)
    }
}
