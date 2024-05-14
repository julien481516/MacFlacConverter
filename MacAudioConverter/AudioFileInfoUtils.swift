//
//  AudioFileInfo.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 13/05/2024.
//

import Foundation

struct AudioFileInfo {
    let sampleRate: Int            // Sample rate in Hz (e.g., 44100)
    let channels: AudioChannelConfiguration // Channel configuration
    let duration: TimeInterval     // Duration in seconds
    let bitrate: Int               // Bitrate in kbps
    let format: AudioFileFormat?   // Audio file format
    let codec: AudioCodec?         // Audio codec used
    let fileSize: Int?             // File size in bytes
    let title: String?             // Title of the audio file
    let artist: String?            // Artist name
    let album: String?             // Album name
    let year: Int?                 // Year of release
    let genre: String?             // Genre of the audio file
    let trackNumber: Int?          // Track number in the album
}


enum AudioFileFormat: String, Identifiable, CaseIterable {
    case wav = "wav"
    case flac = "flac"
    case mp3 = "mp3"
    case aac = "aac"
    case ogg = "ogg"
    case alac = "alac"
    case m4a = "m4a"
    
    var id: String {
        return self.rawValue
    }
    
    static var availableFormats: [AudioFileFormat] {
        return [.wav, .mp3]
    }
}

enum AudioCodec: String {
    case pcm = "PCM"
    case alac = "ALAC"
    case aac = "AAC"
    case mp3 = "MP3"
    case vorbis = "Vorbis"
    case flac = "FLAC"
}

enum AudioChannelConfiguration: String {
    case mono = "Mono"
    case stereo = "Stereo"
    case surround = "Surround"
    
    var numberOfChannels: Int {
        switch self {
        case .mono:
            return 1
        case .stereo:
            return 2
        case .surround:
            return 3
        }
    }
}

