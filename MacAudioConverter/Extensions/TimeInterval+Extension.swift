//
//  TimeInterval+Extension.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 15/05/2024.
//

import Foundation

extension TimeInterval {
    func formattedAsSongLength() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
