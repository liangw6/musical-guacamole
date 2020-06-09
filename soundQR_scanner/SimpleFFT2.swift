//
//  SimpleFFT2.swift
//  soundQR_scanner
//
//  Created by Liang Arthur on 6/9/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
import Accelerate

class SimpleFFT2 {
    let n = 1024
    lazy var log2n: vDSP_Length = vDSP_Length(log2(Float(n)))
    let halfN: Int = 512
    
    var sample_rate: Double = 44100
    var fftSetup: vDSP_DFT_Setup
            
    init () {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil,
                                            vDSP_Length(n),
                                            vDSP_DFT_Direction.FORWARD)!
    }
    
    func set_sample_rate (_ sample_rate: Double) {
        self.sample_rate = sample_rate
    }
    
    func runFFTonSignal(_ signal: [Float]) -> [Float] {
        var forwardInputReal = signal
        var forwardInputImag = [Float](repeating: 0,
                                       count: n)
        var forwardOutputReal = [Float](repeating: 0,
                                        count: n)
        var forwardOutputImag = [Float](repeating: 0,
                                        count: n)
        var forwardOutputMagnitude = [Float](repeating: 0,
                                        count: n)
        
        let forwardOutputRealPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: forwardOutputReal)
        let forwardOutputImagPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: forwardOutputImag)
        vDSP_DFT_Execute(self.fftSetup,
                        forwardInputReal, forwardInputImag,
                        forwardOutputRealPtr, forwardOutputImagPtr)
        let forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr,
                                            imagp: forwardOutputImagPtr)
        vDSP.absolute(forwardOutput, result: &forwardOutputMagnitude)
        
        for magnitude in forwardOutputMagnitude[0...halfN].enumerated() {
            if magnitude.element > 1 {
                print("\(Double(magnitude.offset + 1) * sample_rate / Double(n)) \(magnitude.element)")
            }
        }
        print()
        
        return forwardOutputMagnitude
    }
}
