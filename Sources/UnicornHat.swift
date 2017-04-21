/*
 UnicornHat.swift
 
 Copyright (c) 2017 Daniel Muellenborn
 Licensed under the MIT license, as follows:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */
import SwiftyGPIO

public final class UnicornHat: WS281x {
  
  /// Initializer for Pimoroni Unicorn Hat connected to RPi2
  public convenience init(numberOfLeds: Int = 64, matrixWidth: Int = 8) {
    let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPi2)!
    let pwm = (pwms[0]?[.P18])!
    self.init(pwm, type: .WS2812B, numElements: numberOfLeds)
    self.matrixWidth = matrixWidth
  }

  /// Subscript for leds positioned in a sequential matrix, but viewed as classic matrix,
  /// for easier use of Pimoroni Unicorn Hat.
  public subscript(pos: (x: Int, y: Int)) -> Color {
    get {
      var idx = pos.y*matrixWidth
      idx += (pos.y%2 > 0) ? (matrixWidth-1-pos.x) : pos.x
      return sequence[idx]
    }
    set {
      var idx = pos.y*matrixWidth
      idx += (pos.y%2 > 0) ? (matrixWidth-1-pos.x) : pos.x
      sequence[idx] = newValue
    }    
  }

  public var leds: [Color] {
    get { 
      return getLeds() 
    }
    set {
      precondition(newValue.count == numElements)
      setLeds(newValue) 
    }  
  }

  /// Get the leds positioned as a classic matrix
  func getLeds() -> [Color] {
    var matrix = [Color]()
    for slice in 0..<matrixWidth {
      let startIdx = slice * matrixWidth
      let range = startIdx ..< startIdx + 8
      if (slice + 1) % 2 > 0 {
	      matrix += sequence[range].reversed() 
      } else {
        matrix += sequence[range]
      }
    }
    return matrix
  }

  /// Set the leds in a classic matrix sequence stored in a sequential matrix,
  /// where the first element in a row is connected to the element above
  func setLeds(_ colors: [Color]) {
    var matrix = [Color]()
    for slice in 0..<matrixWidth {
      let startIdx = slice * matrixWidth
      let range = startIdx ..< startIdx + 8
      if (slice + 1) % 2 > 0 {
	      matrix += colors[range].reversed() 
      } else {
        matrix += colors[range]
      }
    }
    sequence = matrix
  }
}

