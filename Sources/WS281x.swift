/*
 WS281x.swift
 
 Copyright (c) 2017 Umberto Raimondi
 Modified by Daniel Muellenborn
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
import Glibc

public class WS281x {
  
  private let type: WSKind
  private let pwm: PWMOutput

  private let frequency: Int
  private let resetDelay: Int
  private let dutyOne: Int
  private let dutyZero: Int

  internal var sequence: [Color]
  public internal(set) var matrixWidth: Int

  public let numElements: Int

  init(_ pwm: PWMOutput, type: WSKind, numElements: Int) {
    
    self.pwm = pwm
    self.type = type
    self.numElements = numElements
    self.matrixWidth = 1
    self.frequency =  type.getDuty().frequency
    self.resetDelay = type.getDuty().resetDelay
    self.dutyZero = type.getDuty().zero
    self.dutyOne = type.getDuty().one
    
    self.sequence = Array(repeating: Color.black, count: numElements)
    // Initialize PWM
    pwm.initPWM()
    pwm.initPWMPattern(bytes: numElements*3,
                       at: type.getDuty().frequency,
                       with: type.getDuty().resetDelay,
                       dutyzero: type.getDuty().zero,
                       dutyone: type.getDuty().one)
  }
    
  /// Set a led using the sequence id
  public func setLed(_ id: Int, rgb: Color){
    sequence[id] = rgb
  }

  public var firstColor: Color? {
    return sequence.first(where: { $0.isVisible })
  }

  public struct Color {

    public var red, green, blue: UInt8
    
    var isVisible: Bool {
      if red > 0 || green > 0 || blue > 0 {
        return true
      }
      return false
    }

    public func cycled() -> Color {
      var color = self
      if color.red > 0 &&
         color.blue == 0 {
        color.red -= 1
        color.green += 1
        return color     
      }
      if green > 0 {
        color.green -= 1
        color.blue += 1
        return color
      }
      if color.blue > 0 {
        color.blue -= 1
        color.red += 1
        return color
      }
      return color
    }

    public init(rgb: UInt32) {
      self.red = UInt8((rgb >> UInt32(16)) & 0xff)
      self.green = UInt8((rgb >> UInt32(8))  & 0xff)
      self.blue = UInt8(rgb & 0xff)
    }

    public init(red: Int, green: Int, blue: Int) {
      self.red = UInt8(red)
      self.green = UInt8(green)
      self.blue = UInt8(blue)
    }

    public init(red: Double, green: Double, blue: Double) {
      let gamma = { UInt8(pow($0, 1.0 / 0.45) * 255.0) }
      self.red = gamma(red)
      self.green = gamma(green)
      self.blue = gamma(blue)
    }

    public static let black   = Color(red: 0, green: 0, blue: 0)
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

  /// Set all leds off
  public func clear() {
    sequence = Array(repeating: Color.black, count: numElements)
  }

  /// Set all leds in given color
  public func setAll(color: Color) {
    sequence = Array(repeating: color, count: numElements)
  }

  /// Change the color of all active leds
  public func active(color: Color) {
    sequence = sequence.map { return $0.isVisible ? color : .black } 
  }

  /// Cycle the color of all active leds
  public func colorCycling() {
    sequence = sequence.map { $0.cycled() } 
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
    byteStream.reserveCapacity(sequence.count * 3)
    for led in sequence {
	    // Add as GRB
      byteStream.append(led.green)
      byteStream.append(led.red)
      byteStream.append(led.blue)
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

