//
//  SimpleFFT.swift
//  soundQR_scanner
//
//  Created by Liang Arthur on 6/8/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//  The FFT component of this file is modified based on Apple's FFT tutorial
//  https://developer.apple.com/documentation/accelerate/finding_the_component_frequencies_in_a_composite_sine_wave
import Foundation
import AVFoundation
import SwiftUI
import Combine
import Accelerate

class SimpleFFT {
    // some constants for FFT
    let n = vDSP_Length(1024)
    lazy var log2n: vDSP_Length = vDSP_Length(log2(Float(n)))
    let halfN: Int = 512
    
    var fftSetup: vDSP.FFT<DSPSplitComplex>!
    
    var sample_rate: Double = 44100
    
    init () {
        fftSetup = vDSP.FFT(log2n: log2n,
            radix: .radix2,
            ofType: DSPSplitComplex.self)
    }
    
    func set_sample_rate (_ sample_rate: Double) {
        self.sample_rate = sample_rate
    }
    
    // returns magnitudes of each bin
    func runFFTonSignal(_ signal: [Float]) -> [Float] {
        var forwardInputReal = [Float](repeating: 0,
                                       count: halfN)
        var forwardInputImag = [Float](repeating: 0,
                                       count: halfN)
        var forwardOutputReal = [Float](repeating: 0,
                                        count: halfN)
        var forwardOutputImag = [Float](repeating: 0,
                                        count: halfN)
        var forwardOutputMagnitude = [Float](repeating: 0,
                                        count: halfN)
        
        
        var highlights_mag = [Float](repeating: 0, count: 15)
//        var highlights_freq = [Float](repeating: 0, count: 15)
        
        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                        
                        // 1: Create a `DSPSplitComplex` to contain the signal.
                        var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                           imagp: forwardInputImagPtr.baseAddress!)
                        
                        // 2: Convert the real values in `signal` to complex numbers.
                        signal.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                         toSplitComplexVector: &forwardInput)
                        }
                        
                        // 3: Create a `DSPSplitComplex` to receive the FFT result.
                        var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                            imagp: forwardOutputImagPtr.baseAddress!)
                        
                        // 4: Perform the forward FFT.
                        self.fftSetup.forward(input: forwardInput,
                                         output: &forwardOutput)
                        
                        // calculate magnitude
//                        print("output highilights")
                        vDSP.absolute(forwardOutput, result: &forwardOutputMagnitude)
                        
//                        highlights_freq = [829, 830, 831, 832, 833, 834, 835, 836, 837, 838, 839, 840, 841, 842, 843]
                        highlights_mag = Array(forwardOutputMagnitude)
                        
                        let lowest_possible = Int(16000 * (Double(n) / sample_rate))
                        let highest_possible = halfN - 1
//                        for magnitude in highlights_mag[lowest_possible...highest_possible].enumerated() {
//                            if magnitude.element > 1 {
//                                print("\(Double(magnitude.offset + 1 + lowest_possible) * sample_rate / Double(n)) \(magnitude.element)")
//                            }
//                        }
                        
                        for magnitude in highlights_mag.enumerated() {
                            if magnitude.element > 1 {
                                print("\(Double(magnitude.offset + 1) * sample_rate / Double(n)) \(magnitude.element)")
                            }
                        }
                        print()
                        
                    }
                }
            }
        }
        return highlights_mag
    }
    
}
