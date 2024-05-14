//
//  ConvertViewModel.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 13/05/2024.
//

import Foundation
import SwiftUI
import Combine

class ConvertViewModel: ObservableObject {
    
    @Published var filesToConvert: [FileImported] = []
    @Published var formatSelected: AudioFileFormat = .wav
    
    var isFormatSelected: Bool {
        formatSelected != nil
    }
    
    var readyToConvert: Bool {
        filesToConvert.count > 0
    }
    
    func handleFiles(urls: [URL]) {
        let importedFiles = urls.map { url in
            print("Importing file: \(url.lastPathComponent)")
            return FileImported(fileURL: url)
        }
        
        DispatchQueue.main.async {
            self.filesToConvert.append(contentsOf: importedFiles)
        }
    }
    
    func triggerConversion() {
        DispatchQueue.main.async {
            if self.readyToConvert {
                for fileToConvert in self.filesToConvert {
                    ConversionManager.shared.readFLACPropertiesAndConvertToPCM(fileURL: fileToConvert.fileURL, outputFilePath: "\(fileToConvert.fileName).\(self.formatSelected.rawValue)")
                }
            }
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.filesToConvert = []
        }
    }
}

