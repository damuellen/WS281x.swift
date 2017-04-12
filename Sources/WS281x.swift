/*
 WS281x.swift
 
 Copyright (c) 2017 Umberto Raimondi
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
import Foundation

public class WS281x {
  
  private let type: WSKind
  private let pwm: PWMOutput
  private let numElements: Int
  private var matrixWidth: Int
  private let frequency: Int
  private let resetDelay: Int
  private let dutyOne: Int
  private let dutyZero: Int
  private var sequence: [UInt32]
  
  public init(_ pwm: PWMOutput, type: WSKind, numElements: Int) {
    
    self.pwm = pwm
    self.type = type
    self.numElements = numElements
    self.matrixWidth = 1
    self.frequency =  type.getDuty().frequency
    self.resetDelay = type.getDuty().resetDelay
    self.dutyZero = type.getDuty().zero
    self.dutyOne = type.getDuty().one
    
    sequence = [UInt32](repeating: 0x0, count: numElements)
    // Initialize PWM
    pwm.initPWM()
    pwm.initPWMPattern(bytes: numElements*3,
                       at: type.getDuty().frequency,
                       with: type.getDuty().resetDelay,
                       dutyzero: type.getDuty().zero,
                       dutyone: type.getDuty().one)
  }
  
  /// Initializer for Pimoroni Unicorn Hat connected to RPi2
  public convenience init(numberOfLeds: Int = 64, matrixWidth: Int = 8) {
    let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPi2)!
    let pwm = (pwms[0]?[.P18])!
    self.init(pwm, type: .WS2812B, numElements: numberOfLeds)
    self.matrixWidth = matrixWidth
  }
  
  /// Set a led using the sequence id
  public func setLed(_ id: Int, r: UInt8, g: UInt8, b: UInt8) {
    sequence[id] = (UInt32(r) << 16) | (UInt32(g) << 8) | (UInt32(b))
  }
  
  /// Set all leds with the colors positioned as GBR
  public func setLeds(_ gbr: [UInt32]) {
    sequence = gbr
  }
  
  /// Set all leds with the colors
  public func setLeds(_ colors: [Color]) {
    sequence = colors.map { $0.rawValue }
  }
  
  public func setLedsOff() {
    sequence = [UInt32](repeating:0x0, count: numElements)
  }
  
  /// Set a led in a sequence viewed as a classic matrix, where each row starts with an id = rownum*width.
  /// Used in some matrixes, es. Nulsom Rainbow Matrix.
  /// Es.
  ///  0  1  2  3
  ///  4  5  6  7
  ///  8  9  10 11
  ///  12 13 14 15
  ///
  public func setLedAsMatrix(x: Int, y:Int, width:Int, r: UInt8, g: UInt8, b: UInt8) {
    sequence[y*width+x] = (UInt32(r) << 16) | (UInt32(g) << 8) | (UInt32(b))
  }
  
  public struct Position {
    let x, y: Int
  }
  
  public struct Color {
    let red, green, blue: UInt8
    
    var rawValue: UInt32 {
      return (UInt32(red) << 16) | (UInt32(green) << 8) | (UInt32(blue))
    }
    
    public static let red     = Color(red: 255, green: 0, blue: 0)
    public static let green   = Color(red: 0, green: 255, blue: 0)
    public static let blue    = Color(red: 0, green: 0, blue: 255)
    public static let white   = Color(red: 128, green: 128, blue: 128)
    public static let yellow  = Color(red: 255, green: 255, blue: 0)
    public static let orange  = Color(red: 255, green: 128, blue: 0)
    public static let purple  = Color(red: 128, green: 0, blue: 128)
    public static let magenta = Color(red: 255, green: 0, blue: 255)
    public static let cyan    = Color(red: 0, green: 255, blue: 255)
  }
  
  public func setLedAsSequentialMatrix(pos: Position, color: Color) {
    setLedAsSequentialMatrix(x: pos.x, y: pos.y, width: matrixWidth, r: UInt8(color.red), g: UInt8(color.green), b: UInt8(color.blue))
  }
  
  /// Set a led in a sequence viewed as a sequential matrix, where the first element in a row is connected to the element above
  /// Rarely used, for example in the Pimoroni Unicorn Hat.
  /// Es.
  ///  3  2  1  0
  ///  4  5  6  7
  ///  11 10 9  8
  ///  12 13 14 15
  ///
  public func setLedAsSequentialMatrix(x: Int, y: Int, width: Int, r: UInt8, g: UInt8, b: UInt8) {
    var pos = y*width
    pos += (y%2 > 0) ? (width-1-x) : x
    sequence[pos] = (UInt32(r) << 16) | (UInt32(g) << 8) | (UInt32(b))
  }
  
  /// Start transmission
  public func start() {
    pwm.sendDataWithPattern(values: toByteStream())
  }
  
  /// Wait for the transmission to end
  public func wait() {
    pwm.waitOnSendData()
  }
  
  /// Clean up once you are done
  public func cleanup() {
    pwm.cleanupPattern()
  }
  
  private func toByteStream() -> [UInt8] {
    var byteStream = [UInt8]()
    for led in sequence {
      // Add as GRB
      byteStream.append(UInt8((led >> UInt32(8))  & 0xff))
      byteStream.append(UInt8((led >> UInt32(16)) & 0xff))
      byteStream.append(UInt8(led  & 0xff))
    }
    return byteStream
  }
}

public enum WSKind {
  case WS2811     //T0H:0.5us T0L:2.0us, T1H:1.2us T1L:1.3us , resDelay > 50us
  case WS2812     //T0H:0.35us T0L:0.8us, T1H:0.7us T1L:0.6us , resDelay > 50us
  case WS2812B    //T0H:0.35us T0L:0.9us, T1H:0.9us T1L:0.35us , resDelay > 50us
  case WS2813     //T0H:0.35us T0L:0.9us, T1H:0.9us T1L:0.35us , resDelay > 250us ?
  
  public func getDuty() -> (zero: Int,one: Int,frequency: Int,resetDelay: Int) {
    switch self {
    case WSKind.WS2811:
      return (33,66,800_000,55)
    case WSKind.WS2812:
      return (33,66,800_000,55)
    case WSKind.WS2812B:
      return (33,66,800_000,55)
    case WSKind.WS2813:
      return (33,66,800_000,255)
    }
  }
}

public extension WS281x.Color {
  
  public init(red: CGFloat, blue: CGFloat, green: CGFloat) {
    self.init(red: UInt8(CGFloat(UInt8.max) * red),
              green: UInt8(CGFloat(UInt8.max) * green),
              blue: UInt8(CGFloat(UInt8.max) * blue))
  }
}



