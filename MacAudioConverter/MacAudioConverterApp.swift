//
//  MacAudioConverterApp.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 03/05/2024.
//

import SwiftUI

@main
struct MacAudioConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ConvertView()
                .modifier(WindowModifier())
        }
    }
}


struct WindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
            .onAppear {
                setWindowSize()
            }
    }
    
    private func setWindowSize() {
        guard let window = NSApplication.shared.windows.first else {
            return
        }
        
        if let screenSize = NSScreen.main?.frame.size {
            let windowWidth = screenSize.width * 0.6
            let windowHeight = screenSize.height * 0.6
            let windowSize = CGSize(width: windowWidth, height: windowHeight)
            
            window.setContentSize(windowSize)
            window.center()
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
                window.title = Strings.AppGenerals.appTitle
            }
        }
        return nsView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

