//
//  ResultManager.swift
//  soundQR_scanner
//
//  Created by Liang Arthur on 6/8/20.
//  Copyright © 2020 Liang Arthur. All rights reserved.
//

import Foundation
class ResultManager: ObservableObject {
    let data_seq_len = 26
    let check_sum_len = 5
    var resultSoFar = [Int]()
    let lowest_possible = Int(16000 * (Double(1024) / 44100))
    let highest_possible = 512 - 1
    
    let freq_0_bit: Double = 18000
    let freq_1_bit: Double = 19000
    
    // For Preambles
    let preambleSequence: [Int] = [0, 1, 0, 1, 1, 0]      //  [0, 1, 0, 0]
    var detectedPreamble = false
    // Preamble Array is to be used as a circular buffer
    let preambleBufferSize = 20
    lazy var preambleBuffer = [Int](repeating: 0, count: self.preambleBufferSize)
    var preambleHeadIdx = 0
    var preambleTailIdx = 0
    
    let data2song_name = ["01001101110100011001010010": "Scarborough-Fair"]
    @Published var curr_song_name = "None"

    func getDatabit(_ highlight_freq: [Double], _ highlight_mag:[Double], forceResult: Bool = false) -> Int {
        var dataBit = -1
        if forceResult {
            // always guess 0 if forceResult is set
            dataBit = 0
        }
        
        if highlight_freq.count == 0 {
            // no freq -> no data
            return dataBit
        }
        
        // we only care about high frequencies
        var pass_band_freq: [Double] = [Double]()
        var pass_band_mag: [Double] = [Double]()
        for idx in 0...(highlight_freq.count - 1) {
            if (highlight_freq[idx] >= freq_0_bit) {
                pass_band_freq.append(highlight_freq[idx])
                pass_band_mag.append(highlight_mag[idx])
            }
        }
        
        if (pass_band_freq.count >= 1) {
            // passed digital highband filter
            
            // extract frequency with maximum magnitude
            let max_idx = pass_band_mag.argmax()!
            let max_mag_freq = pass_band_freq[max_idx]
            
            // if that freq is closer to 18K, then it's 0
            // otherwise 1
            let diff_with_freq_0 = abs(max_mag_freq - freq_0_bit)
            let diff_with_freq_1 = abs(max_mag_freq - freq_1_bit)
            if diff_with_freq_0 < diff_with_freq_1 {
                dataBit = 0
            } else {
                dataBit = 1
            }
        }
        
        // sanity check with prints
//        print("input is ...")
//        for idx in 0...(highlight_freq.count - 1) {
//            print("\(highlight_freq[idx]) \(highlight_mag[idx])")
//        }
//        print("databit is \(dataBit)")
//        print()
        
        return dataBit
    }

    // append to result when detectedPreamble
    func appendResult(_ dataBit: Int) {
        self.resultSoFar.append(dataBit)
        if (self.resultSoFar.count >= self.data_seq_len + self.check_sum_len) {
            // checksum!!
            let curr_sum = self.resultSoFar[0...(self.data_seq_len - 1)].reduce(0, +)
            let curr_check_sum_string = self.resultSoFar[(self.data_seq_len)...(self.resultSoFar.count - 1)].map{String($0)}.reduce("", +)
            let curr_check_sum = Int(curr_check_sum_string, radix: 2)!
            print("curr result:")
            print("result buffer \(self.resultSoFar)")
            print("curr_sum \(curr_sum) = curr_check_sum \(curr_check_sum) is \(curr_sum == curr_check_sum)")
            
            if (curr_sum == curr_check_sum) {
                print("check sum succeeded!")
                let curr_bit_string = self.resultSoFar[0...(self.data_seq_len - 1)].map{String($0)}.reduce("", +)
                // updating....
                DispatchQueue.main.async {
                    self.curr_song_name = self.data2song_name[curr_bit_string]!
                }
                print("curr song name is now \(self.curr_song_name)")
            }
            
            self.clearPreambleAndResult()
        }
    }

    // append to preamble when !detectedPreamble
    func appendPreamble(_ dataBit: Int) {
        if (self.detectedPreamble) {
            print("Already Detected Preamble!!!!")
            return
        }
        
        preambleBuffer[preambleTailIdx % (preambleBuffer.count)] = dataBit
        if (preambleTailIdx - preambleHeadIdx) >= preambleSequence.count - 1 {
            // try to match the preamble
            var allBitsMatch = true
            for idx in preambleHeadIdx...preambleTailIdx {
                if (preambleBuffer[idx % preambleBuffer.count] != preambleSequence[idx - preambleHeadIdx]) {
                    allBitsMatch = false
                }
            }
            
            if allBitsMatch {
                print("found preamble!!!!!")
            }
            
            self.detectedPreamble = allBitsMatch
            self.preambleHeadIdx += 1
        }
        // tail idx always points to the next usused
        self.preambleTailIdx += 1
    }
    
    // call this function when we are done with a sequence of data
    func clearPreambleAndResult() {
        self.preambleHeadIdx = 0
        self.preambleTailIdx = 0
        self.preambleBuffer = [Int](repeating: 0, count: self.preambleBufferSize)
        self.detectedPreamble = false
        
        // clear results
        self.resultSoFar = [Int]()
    }
    
}


extension Array where Element: Comparable {
    func argmax() -> Index? {
        return indices.max(by: { self[$0] < self[$1] })
    }
    
    func argmin() -> Index? {
        return indices.min(by: { self[$0] < self[$1] })
    }
}
