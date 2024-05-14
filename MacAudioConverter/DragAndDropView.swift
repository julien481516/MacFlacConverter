//
//  DocumentPicker.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 03/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct DragAndDropView: View {
    @ObservedObject var viewModel: ConvertViewModel
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Text("Drag and drop FLAC files here")
                .frame(width: 300, height: 150)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    DispatchQueue.main.async {
                        handleDrop(providers: providers)
                    }
                    return true
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Unsupported File Format"),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }

            Image(systemName: "plus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60)
                .padding(.bottom, 50)
        }
        .cornerRadius(13.0)
        .padding(50)
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                if let data = data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   error == nil {
                    if url.pathExtension.lowercased() == AudioFileFormat.flac.rawValue {
                        DispatchQueue.main.async {
                            viewModel.handleFiles(urls: [url])
                        }
                    } else {
                        DispatchQueue.main.async {
                            alertMessage = "The file \(url.lastPathComponent) is not a supported format. Please drop a FLAC file."
                            showAlert = true
                        }
                    }
                } else {
                    print("❌ ERROR FILE IMPORT: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        alertMessage = "Error importing file: \(error?.localizedDescription ?? "Unknown error")"
                        showAlert = true
                    }
                }
            }
        }
    }
}
