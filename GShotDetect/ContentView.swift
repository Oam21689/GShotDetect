//
//  ContentView.swift
//  GShotDetect
//
//  Created by Olame Muliri on 3/09/23.
//

import SwiftUI
import UIKit
import AVFoundation
import CoreAudio
import CoreML

struct ContentView: View {
    let audioEngine = AVAudioEngine()
    let soundClassifier = MySoundClassifier()
    @State private var classification: String = ""
    @State private var isRecording = false
    @State private var isRecordingInProgress = false
    
    var body: some View {
        VStack {
            Image("base_text-logoname_transparent_background")
                .resizable()
                .scaledToFit()
                .foregroundColor(.black)
            Image(systemName: "scribble.variable")
                .imageScale(.large)
                .foregroundColor(.white)
            Text("Click to classify sound!")
                .foregroundColor(.white)
            if isRecordingInProgress {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
            }
            Button(action: {
                self.isRecording.toggle()
                if self.isRecording {
                    self.startRecording()
                } else {
                    self.stopRecording()
                }
            }) {
                Circle()
                    .foregroundColor(Color(red: 234/255, green: 170/255, blue: 0))
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "waveform.and.mic")
                        .imageScale(.large)
                        .foregroundColor(isRecording ? .red : .black)
                        .font(.system(size: 30)))
            }
        }
        .padding()
        .preferredColorScheme(.dark)
        Text(classification)
            .foregroundColor(.white)
    }
    func startRecording() {
        let inputNode = audioEngine.inputNode

        // Remove any existing taps on the input node
        inputNode.removeTap(onBus: 0)

        // Set the recording format's sample rate to match the input node's sample rate
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputNode.inputFormat(forBus: 0).sampleRate, channels: 1, interleaved: false)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            let prediction = try? self.soundClassifier.prediction(buffer: buffer)
            self.classification = prediction?.classLabel ?? "Unknown"
        }

        do {
            try audioEngine.start()
            isRecordingInProgress = true
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecordingInProgress = false
    }
    class MySoundClassifier {
        private let model: Gunshotdetect
        
        init() {
            model = try! Gunshotdetect(configuration: MLModelConfiguration())
        }
        
        func prediction(buffer: AVAudioPCMBuffer) throws -> GunshotdetectOutput {
            let audioData = buffer.floatChannelData!.pointee
            let audioBuffer = try MLMultiArray(shape: [buffer.frameLength as NSNumber], dataType: MLMultiArrayDataType.float32)
            for i in 0..<Int(buffer.frameLength) {
                audioBuffer[i] = NSNumber(value: audioData[i])
            }
            let input = GunshotdetectInput(audioSamples: audioBuffer)
            return try model.prediction(input: input)
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
