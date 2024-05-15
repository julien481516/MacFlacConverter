//
//  ConvertViewModel.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 13/05/2024.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

class ConvertViewModel: ObservableObject {
    @Published var filesToConvert: [FileImported] = []
    @Published var formatSelected: AudioFileFormat = .wav
    @Published var progress: Double = 0.0 {
        didSet {
            print("xoxo progress : \(progress.description)")
        }
    }
    
    var isFormatSelected: Bool {
        formatSelected != nil
    }
    
    var readyToConvert: Bool {
        filesToConvert.count > 0
    }
    
    func handleFiles(urls: [URL]) {
        let importedFiles = urls.compactMap { url -> FileImported? in
            print("Importing file: \(url.lastPathComponent)")
            if let audioFileInfo = analyzeAudioFile(url: url) {
                return FileImported(fileURL: url, audioFileInfo: audioFileInfo)
            } else {
                print("Invalid audio file: \(url.lastPathComponent)")
                return nil
            }
        }
        
        DispatchQueue.main.async {
            self.filesToConvert.append(contentsOf: importedFiles)
        }
    }
    
    func analyzeAudioFile(url: URL) -> AudioFileInfo? {
        let validExtensions = AudioFileFormat.allCases.map({ $0.rawValue })
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            print("Unsupported file extension: \(url.pathExtension)")
            return nil
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.fileFormat
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int
            
            // Calculate bitrate
            let bitDepth = format.settings[AVLinearPCMBitDepthKey] as? Int ?? 16
            let bitrate = Int(format.sampleRate) * bitDepth * Int(format.channelCount)
            
            // Extracting metadata (optional, depending on the audio file)
            let asset = AVURLAsset(url: url)
            let metadata = asset.commonMetadata
            let title = metadata.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue
            let artist = metadata.first(where: { $0.commonKey?.rawValue == "artist" })?.stringValue
            let album = metadata.first(where: { $0.commonKey?.rawValue == "albumName" })?.stringValue
            let year = metadata.first(where: { $0.commonKey?.rawValue == "creationDate" })?.stringValue.flatMap { Int($0) }
            let genre = metadata.first(where: { $0.commonKey?.rawValue == "type" })?.stringValue
            let trackNumber = metadata.first(where: { $0.commonKey?.rawValue == "trackNumber" })?.numberValue?.intValue
            
            let audioFileInfo = AudioFileInfo(
                sampleRate: Int(format.sampleRate),
                channels: AudioChannelConfiguration(rawValue: Int(format.channelCount)) ?? .other,
                duration: audioFile.length > 0 ? TimeInterval(audioFile.length) / format.sampleRate : 0,
                bitrate: bitrate,
                format: AudioFileFormat(rawValue: url.pathExtension.lowercased()),
                codec: AudioCodec(rawValue: format.settings[AVFormatIDKey] as? String ?? "Other"),
                fileSize: fileSize,
                title: title,
                artist: artist,
                album: album,
                year: year,
                genre: genre,
                trackNumber: trackNumber
            )
            
            return audioFileInfo
        } catch {
            print("Error analyzing file: \(error.localizedDescription)")
            return nil
        }
    }
    
    func triggerConversion() {
        DispatchQueue.main.async {
            if self.readyToConvert {
                for (i, fileToConvert) in self.filesToConvert.enumerated() {
                    ConversionManager.shared.readFLACPropertiesAndConvertToPCM(
                        fileURL: fileToConvert.fileURL,
                        outputFilePath: "\(fileToConvert.fileURL.deletingPathExtension().lastPathComponent).\(self.formatSelected.rawValue)"
                    )
                    print("index : \(i)")
                    print("filesToConvert.count : \(self.filesToConvert.count)")
                    self.progress = Double(i + 1) / Double(self.filesToConvert.count)
                    print("progress = \(self.progress)")
                }
            }
        }
    }
    
    func deleteFiles(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.filesToConvert.remove(atOffsets: offsets)
        }
    }
    
    func clearAll() {
        DispatchQueue.main.async {
            self.filesToConvert.removeAll()
            self.progress = 0.0
        }
    }
}
