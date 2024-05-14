//
//  ConversionManager.swift
//  MacAudioConverter
//
//  Created by Julien AGOSTINI on 03/05/2024.
//
//

import AVFoundation
import CoreMedia

class ConversionManager {
    static let shared: ConversionManager = ConversionManager()
    
    func readFLACPropertiesAndConvertToPCM(fileURL: URL, outputFilePath: String) {
        do {
            let asset = AVAsset(url: fileURL)
            guard let track = asset.tracks(withMediaType: .audio).first else {
                print("❌ No audio tracks found in the file.")
                return
            }
            
            let formatDescriptions = track.formatDescriptions as! [CMAudioFormatDescription]
            guard let formatDescription = formatDescriptions.first else {
                print("❌ No format descriptions found in the audio track.")
                return
            }
            
            let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
            let sampleRate = Int(audioStreamBasicDescription?.mSampleRate ?? 0)
            let channels = Int(audioStreamBasicDescription?.mChannelsPerFrame ?? 0)
            let bitrate = Int(track.estimatedDataRate / 1000)
            let duration = asset.duration.seconds
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
            
            let audioFileInfo = AudioFileInfo(
                sampleRate: sampleRate,
                channels: AudioChannelConfiguration(rawValue: "\(channels)") ?? .stereo,
                duration: duration,
                bitrate: bitrate,
                format: .flac,
                codec: .flac,
                fileSize: fileSize,
                title: nil,
                artist: nil,
                album: nil,
                year: nil,
                genre: nil,
                trackNumber: nil
            )
            
            print("AudioFileInfo: \(audioFileInfo)")
            
            let result = decodeFLAC(fileURL: fileURL)
            switch result {
            case .success(let pcmData):
                try writePCMDataToWAVFile(pcmData: pcmData, fileInfo: audioFileInfo, outputFilePath: outputFilePath)
                print("✅ Successfully converted FLAC to PCM and wrote to file.")
            case .failure(let error):
                print("❌ Failed to decode FLAC file: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    private func decodeFLAC(fileURL: URL) -> Result<Data, Error> {
        do {
            let asset = AVAsset(url: fileURL)
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                let error = NSError(domain: "FLACDecoder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not initialize AVAssetReader"])
                return .failure(error)
            }
            
            guard let track = asset.tracks(withMediaType: .audio).first else {
                let error = NSError(domain: "FLACDecoder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No audio tracks found in the file"])
                return .failure(error)
            }

            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false
            ]
            let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            assetReader.add(readerOutput)

            guard assetReader.startReading() else {
                let error = NSError(domain: "FLACDecoder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not start reading asset"])
                return .failure(error)
            }

            var pcmData = Data()
            var operationError: NSError?
            
            while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                defer { CMSampleBufferInvalidate(sampleBuffer) }
                guard let sampleBufferPointer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                    operationError = NSError(domain: "FLACDecoder", code: 4, userInfo: [NSLocalizedDescriptionKey: "Audio decoding error"])
                    break
                }

                let dataLength = CMBlockBufferGetDataLength(sampleBufferPointer)
                var bufferData = Data(count: dataLength)

                let status = bufferData.withUnsafeMutableBytes { bytes -> OSStatus in
                    guard let baseAddress = bytes.baseAddress else {
                        operationError = NSError(domain: "FLACDecoder", code: 5, userInfo: [NSLocalizedDescriptionKey: "Memory access error"])
                        return noErr
                    }
                    return CMBlockBufferCopyDataBytes(sampleBufferPointer, atOffset: 0, dataLength: dataLength, destination: baseAddress)
                }

                if status != kCMBlockBufferNoErr {
                    operationError = NSError(domain: "FLACDecoder", code: 6, userInfo: [NSLocalizedDescriptionKey: "Error copying audio data"])
                    break
                }

                if let error = operationError {
                    return .failure(error)
                }

                pcmData.append(bufferData)
            }

            if let error = operationError {
                return .failure(error)
            }

            switch assetReader.status {
            case .completed:
                return .success(pcmData)
            case .failed, .cancelled:
                return .failure(assetReader.error ?? NSError(domain: "FLACDecoder", code: 7, userInfo: [NSLocalizedDescriptionKey: "Error during reading audio"]))
            default:
                break
            }
        } catch {
            return .failure(error)
        }
        return .failure(NSError(domain: "FLACDecoder", code: 8, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
    }
    
    private func writePCMDataToWAVFile(pcmData: Data, fileInfo: AudioFileInfo, outputFilePath: String) throws {
        let wavHeader = createWAVHeader(dataLength: pcmData.count, fileInfo: fileInfo)
        var wavFileData = wavHeader
        wavFileData.append(pcmData)
        try wavFileData.write(to: URL(fileURLWithPath: outputFilePath))
    }

    private func createWAVHeader(dataLength: Int, fileInfo: AudioFileInfo) -> Data {
        var wavHeader = Data()
        wavHeader.append("RIFF".data(using: .ascii)!)
        let chunkSize = dataLength + 36
        var chunkSizeBytes = withUnsafeBytes(of: UInt32(chunkSize).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: chunkSizeBytes)
        wavHeader.append("WAVE".data(using: .ascii)!)
        wavHeader.append("fmt ".data(using: .ascii)!)
        let subchunk1Size: UInt32 = 16
        var subchunk1SizeBytes = withUnsafeBytes(of: UInt32(subchunk1Size).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: subchunk1SizeBytes)
        var audioFormatBytes = withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: audioFormatBytes)
        var numChannelsBytes = withUnsafeBytes(of: UInt16(fileInfo.channels.numberOfChannels).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: numChannelsBytes)
        var sampleRateBytes = withUnsafeBytes(of: UInt32(fileInfo.sampleRate).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: sampleRateBytes)
        let byteRate = fileInfo.sampleRate * fileInfo.channels.numberOfChannels * 16 / 8
        var byteRateBytes = withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: byteRateBytes)
        let blockAlign = fileInfo.channels.numberOfChannels * 16 / 8
        var blockAlignBytes = withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: blockAlignBytes)
        var bitsPerSampleBytes = withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: bitsPerSampleBytes)
        wavHeader.append("data".data(using: .ascii)!)
        var subchunk2SizeBytes = withUnsafeBytes(of: UInt32(dataLength).littleEndian) { Data($0) }
        wavHeader.append(contentsOf: subchunk2SizeBytes)
        return wavHeader
    }
}
