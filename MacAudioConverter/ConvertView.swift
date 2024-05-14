//
//  ContentView.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 03/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers


struct ConvertView: View {
    
    @ObservedObject var viewModel: ConvertViewModel = ConvertViewModel()
    
    @State private var isFilePickerOpen = false
    
    @State var state: ConversionState = .notConverted
    
    var body: some View {
        VStack(spacing: 20) {
            
#if DEBUG
            Button {
                print("filesToConvert : \(viewModel.filesToConvert)")
            } label: {
                Text("Print filesToConvert")
            }
#endif
            Spacer()
            Text(Strings.AppGenerals.appTitle)
                .font(.system(size: 80))
            
            Button("Select FLAC File") {
                isFilePickerOpen = true
            }
            .buttonStyle(.borderedProminent)
            
            
            if viewModel.filesToConvert.isEmpty {
                Text("No file selected")
                    .italic()
                    .foregroundStyle(.gray)
                DragAndDropView(viewModel: viewModel)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.filesToConvert.sorted(), id: \.self) { file in
                        Text(file.fileName)
                            .padding(1)
                            .foregroundStyle(.green)
                    }
                }
                .frame(height: 150)
                HStack {
                    Spacer()
                    Text(Strings.Labels.totalFilesImported)
                    Text(viewModel.filesToConvert.count.description)
                        .fontWeight(.bold)
                    
                }
                
                
                Picker("", selection: $viewModel.formatSelected) {
                    ForEach(AudioFileFormat.availableFormats) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button {
                    viewModel.triggerConversion()
                } label: {
                    Text(Strings.Labels.convert)
                }
                .buttonStyle(CustomButtonStyle())
                
                Button {
                    print("RESET")
                    self.viewModel.reset()
                } label: {
                    Text(Strings.Labels.reset.uppercased())
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .fileImporter(
            isPresented: $isFilePickerOpen,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                viewModel.handleFiles(urls: urls)
            case .failure(let error):
                print("❌ ERROR IMPORTING FILES : \(error.localizedDescription)")
            }
        }
    }
}


enum ConversionState {
    case notConverted
    case converted
}


#Preview {
    ConvertView(viewModel: ConvertViewModel(), state: .notConverted)
        .modifier(WindowModifier())
}
