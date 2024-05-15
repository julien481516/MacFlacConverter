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
            
//#if DEBUG
//            Button {
//                print("filesToConvert : \(viewModel.filesToConvert)")
//            } label: {
//                Text("Print filesToConvert")
//            }
//#endif
            Spacer()
            
            Text(Strings.AppGenerals.appTitle)
                .font(.system(size: 30))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity) // Take as much space as possible within the superview
                .multilineTextAlignment(.center) // Center align the text
            
            if viewModel.filesToConvert.isEmpty {
                Text("No files selected")
                    .italic()
                    .foregroundStyle(.gray)
                DragAndDropView(viewModel: viewModel)
                    .frame(height: 500)
            } else {
                VStack {
                    ScrollView {
                        List {
                            ForEach(viewModel.filesToConvert.sorted(), id: \.self) { file in
                                HStack {
                                    Text(file.fileName)
                                        .padding(1)
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Text(file.audioFileInfo?.duration.formattedAsSongLength() ?? "")
                                        .foregroundStyle(.green)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 2)
                            }
                            .onDelete(perform: viewModel.deleteFiles)
                        }
                        .frame(height: 500)
                    }
                    .frame(width: 1000, height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    HStack {
                        Spacer()
                        HStack(alignment: .center) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                                .padding(.trailing, 0)
                            
                            Button {
                                self.viewModel.clearAll()
                            } label: {
                                Text(Strings.Labels.clearAll)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 0)
                        }
                        .padding(.horizontal, 20)
                        
                    }
                    .padding(.top, 5)
                    .frame(width: 1000)
                }
                
                HStack {
                    Spacer()
                    Text(Strings.Labels.totalFilesImported)
                    Text(viewModel.filesToConvert.count.description)
                        .fontWeight(.bold)
                }
                .frame(width: 1000)
                
                Text("Desired output :")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity) // Take as much space as possible within the superview
                    .multilineTextAlignment(.center) // Center align the text
                
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
                
                if viewModel.progress > 0 {
                    VStack {
                        ProgressView(value: viewModel.progress)
                            .tint(viewModel.progress == 1 ? .green : .blue)
                            .frame(height: 30)
                            .padding()
                        
                        Text("\(Int(viewModel.progress * 100)) %")
                            .foregroundStyle(viewModel.progress == 1 ? .green : .blue)
                    }
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
    ConvertView(viewModel: ConvertViewModel(), state: .converted)
        .frame(width: 800, height: 800)
}
