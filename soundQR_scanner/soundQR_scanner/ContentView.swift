//
//  ContentView.swift
//  soundQR_scanner
//
//  Created by Liang Arthur on 6/8/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import SwiftUI
import AVFoundation
import Accelerate
import CoreGraphics

struct ContentView: View {
        
    let engine = AVAudioEngine()
    var simpleFFT: SimpleFFT = SimpleFFT()
    var resultManager: ResultManager = ResultManager()
    
//    var simpleFFT: SimpleFFT2 = SimpleFFT2()
    let data_seq_len = 26
    
    var body: some View {
        Button(action: {
//          print("button was tapped")
            // set up engine for the FFT recording
            let input = self.engine.inputNode
            let bus = 0
            let inputFormat = input.inputFormat(forBus: bus)
            // the most recent samples that we are keeping in the circular buffer
            // Here is the last 5 sec
            self.simpleFFT.set_sample_rate(inputFormat.sampleRate) // AVAudioFrameCount(inputFormat.sampleRate * 5)
            input.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { (buffer, time) -> Void in
                buffer.frameLength = 1024
                self.gotSomeAudio(buffer)
            }
            // set up engine for source node
            let output = self.engine.outputNode
//            let srcNode = playSignalSound(Float(output.outputFormat(forBus: 0).sampleRate), frequency: 18000)
//            self.engine.attach(srcNode)
//            self.engine.connect(srcNode, to: output, format: inputFormat)
            
//                print("input sample rate \(inputFormat.sampleRate)")
//                print("output sample rate \(output.outputFormat(forBus: 0).sampleRate)")
            assert(inputFormat.sampleRate == 44100)
            assert(output.outputFormat(forBus: 0).sampleRate == 44100)
            
            // start the engine
            // which should start recording and signal generation
            do {
                try self.engine.start()
            } catch {
                print("Could not start engine: \(error)")
                return
            }
            
            // start the recording
            print("starting")

            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                print("stopping")
                self.endRecording()
            }
        }) {
            Text("Start")
        }
    }
    
    func gotSomeAudio(_ buffer: AVAudioPCMBuffer) {
        
        var samples:[Float] = []
    //        print("framelength \(buffer.frameLength)")
        for i in 0 ..< 1024 {
                let theSample = (buffer.floatChannelData?.pointee[i])!
                samples.append(theSample)
            }
    //        print("input framelength \(samples.count)")
        let (hgihlight_freq, highlight_mag) = self.simpleFFT.runFFTonSignal(samples)
        let currDataBit = resultManager.getDatabit(hgihlight_freq, highlight_mag)
        if (!self.resultManager.detectedPreamble) {
            self.resultManager.appendPreamble(currDataBit)
        } else {
            self.resultManager.appendResult(currDataBit)
            if (self.resultManager.resultSoFar.count >= self.data_seq_len) {
                // we've collected all data bits!
                print("all data bits \(self.resultManager.resultSoFar)")
                
                // ready for next collection
                self.resultManager.clearPreambleAndResult()
            }
        }
            
//            self.leftResultBuffer.addNewResult(Array(self.magnitudeBuffer[0...6]))
//            self.rightResultBuffer.addNewResult(Array(self.magnitudeBuffer[8...14]))
//
//            if self.leftResultBuffer.passThreshold() {
//                self.pushOrPullState = "Pull"
//            } else if self.rightResultBuffer.passThreshold() {
//                self.pushOrPullState = "Push"
//            } else {
//                self.pushOrPullState = "None"
//            }

        }
        
    func endRecording() {
        self.engine.stop()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
