//
//  CustomButtonStyle.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 13/05/2024.
//

import Foundation
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(configuration.isPressed ? Color.blue.opacity(0.5) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(5)
    }
}
