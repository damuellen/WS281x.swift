/*
 PixelFont.swift
 
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
import Glibc
  
public typealias LED = UnicornHat.Color

public struct PixelFont {
  
  private let colors: [LED]
  private let table: [String : PixelFont.Symbol]
  
  public func convert(string: String) -> [PixelFont.Symbol] {
    return string.characters.map { String($0) }.flatMap { table[$0] }
  }
  
  public enum Mode {
    case cyclic, random
  }

  public func makeColoredText(_ symbols: [PixelFont.Symbol],
                             colorMode: Mode = .cyclic) -> [LED] {

    let nextColor: () -> LED
    var colorCycle = colors.makeIterator()
    
    func cycleColor() -> LED {
      if let color = colorCycle.next() {
        return color
      } else {
        colorCycle = colors.makeIterator()
        return colorCycle.next()!
      }
    }
    
    func randomColor() -> LED {
      let random: (Int) -> Int = {
        while true {
          let x = Glibc.random() % $0
          let y = Glibc.random() % $0
          guard x == y else { return x }
        }
      }
      return colors[random(colors.count - 1)]
    }
    
    if colors.count > 1 {  
      switch colorMode {
      case .cyclic:
        nextColor = cycleColor
      case .random:
        nextColor = randomColor
      }
    } else {
      nextColor = { 
       return self.colors.first! 
      }
    }

    let leds: [LED] = symbols.flatMap { symbol in
      symbol.colored(nextColor())
    }

    return leds
  }

  public func makeTextMatrix(_ symbols: [PixelFont.Symbol],
                              color: LED = .red) -> [[Bool]] {

    let pixels: [[Bool]] = symbols.map { symbol in
      symbol.pixelMatrix
    }

    return pixels
  }
  
  public struct Symbol {
    
    let rawValue: [UInt8]
    
    var pixelMatrix: [Bool] {
      return (rawValue + [0]).flatMap { integer in
        return (0...7).map { bit in
          integer & UInt8(0x1 << bit) != 0
        }
      }
    }
    
    public init(rawValue: [UInt8]) {
      self.rawValue = rawValue
    }

    public func colored(_ color: LED) -> [LED] {
      return pixelMatrix.map { $0 ? color : LED.black } 
    }
  }
  
  public init(colors: [LED] = [LED.white]) {
    self.colors = colors
    var dict: [String : Symbol] = [:]
    dict["A"] = Symbol(rawValue: [0x7F, 0x88, 0x88, 0x88, 0x7F])
    dict["B"] = Symbol(rawValue: [0xFF, 0x91, 0x91, 0x91, 0x6E])
    dict["C"] = Symbol(rawValue: [0x7E, 0x81, 0x81, 0x81, 0x42])
    dict["D"] = Symbol(rawValue: [0xFF, 0x81, 0x81, 0x42, 0x3C])
    dict["E"] = Symbol(rawValue: [0xFF, 0x91, 0x91, 0x91, 0x81])
    dict["F"] = Symbol(rawValue: [0xFF, 0x90, 0x90, 0x90, 0x80])
    dict["G"] = Symbol(rawValue: [0x7E, 0x81, 0x89, 0x89, 0x4E])
    dict["H"] = Symbol(rawValue: [0xFF, 0x10, 0x10, 0x10, 0xFF])
    dict["I"] = Symbol(rawValue: [0x81, 0x81, 0xFF, 0x81, 0x81])
    dict["J"] = Symbol(rawValue: [0x06, 0x01, 0x01, 0x01, 0xFE])
    dict["K"] = Symbol(rawValue: [0xFF, 0x18, 0x24, 0x42, 0x81])
    dict["L"] = Symbol(rawValue: [0xFF, 0x01, 0x01, 0x01, 0x01])
    dict["M"] = Symbol(rawValue: [0xFF, 0x40, 0x30, 0x40, 0xFF])
    dict["N"] = Symbol(rawValue: [0xFF, 0x40, 0x30, 0x08, 0xFF])
    dict["O"] = Symbol(rawValue: [0x7E, 0x81, 0x81, 0x81, 0x7E])
    dict["P"] = Symbol(rawValue: [0xFF, 0x88, 0x88, 0x88, 0x70])
    dict["Q"] = Symbol(rawValue: [0x7E, 0x81, 0x85, 0x82, 0x7D])
    dict["R"] = Symbol(rawValue: [0xFF, 0x88, 0x8C, 0x8A, 0x71])
    dict["S"] = Symbol(rawValue: [0x61, 0x91, 0x91, 0x91, 0x8E])
    dict["T"] = Symbol(rawValue: [0x80, 0x80, 0xFF, 0x80, 0x80])
    dict["U"] = Symbol(rawValue: [0xFE, 0x01, 0x01, 0x01, 0xFE])
    dict["V"] = Symbol(rawValue: [0xF0, 0x0C, 0x03, 0x0C, 0xF0])
    dict["W"] = Symbol(rawValue: [0xFF, 0x02, 0x0C, 0x02, 0xFF])
    dict["X"] = Symbol(rawValue: [0xC3, 0x24, 0x18, 0x24, 0xC3])
    dict["Y"] = Symbol(rawValue: [0xE0, 0x10, 0x0F, 0x10, 0xE0])
    dict["Z"] = Symbol(rawValue: [0x83, 0x85, 0x99, 0xA1, 0xC1])
    dict["a"] = Symbol(rawValue: [0x06, 0x29, 0x29, 0x29, 0x1F])
    dict["b"] = Symbol(rawValue: [0xFF, 0x09, 0x11, 0x11, 0x0E])
    dict["c"] = Symbol(rawValue: [0x1E, 0x21, 0x21, 0x21, 0x12])
    dict["d"] = Symbol(rawValue: [0x0E, 0x11, 0x11, 0x09, 0xFF])
    dict["e"] = Symbol(rawValue: [0x0E, 0x15, 0x15, 0x15, 0x0C])
    dict["f"] = Symbol(rawValue: [0x08, 0x7F, 0x88, 0x80, 0x40])
    dict["g"] = Symbol(rawValue: [0x30, 0x49, 0x49, 0x49, 0x7E])
    dict["h"] = Symbol(rawValue: [0xFF, 0x08, 0x10, 0x10, 0x0F])
    dict["i"] = Symbol(rawValue: [0x5F])
    dict["j"] = Symbol(rawValue: [0x02, 0x01, 0x21, 0xBE])
    dict["k"] = Symbol(rawValue: [0xFF, 0x04, 0x0A, 0x11])
    dict["l"] = Symbol(rawValue: [0x81, 0xFF, 0x01])
    dict["m"] = Symbol(rawValue: [0x3F, 0x20, 0x18, 0x20, 0x1F])
    dict["n"] = Symbol(rawValue: [0x3F, 0x10, 0x20, 0x20, 0x1F])
    dict["o"] = Symbol(rawValue: [0x0E, 0x11, 0x11, 0x11, 0x0E])
    dict["p"] = Symbol(rawValue: [0x3F, 0x24, 0x24, 0x24, 0x18])
    dict["q"] = Symbol(rawValue: [0x10, 0x28, 0x28, 0x18, 0x3F])
    dict["r"] = Symbol(rawValue: [0x1F, 0x08, 0x10, 0x10, 0x08])
    dict["s"] = Symbol(rawValue: [0x09, 0x15, 0x15, 0x15, 0x02])
    dict["t"] = Symbol(rawValue: [0x20, 0xFE, 0x21, 0x01, 0x02])
    dict["u"] = Symbol(rawValue: [0x1E, 0x01, 0x01, 0x02, 0x1F])
    dict["v"] = Symbol(rawValue: [0x1C, 0x02, 0x01, 0x02, 0x1C])
    dict["w"] = Symbol(rawValue: [0x1E, 0x01, 0x0E, 0x01, 0x1E])
    dict["x"] = Symbol(rawValue: [0x11, 0x0A, 0x04, 0x0A, 0x11])
    dict["y"] = Symbol(rawValue: [0x39, 0x05, 0x05, 0x3E])
    dict["z"] = Symbol(rawValue: [0x11, 0x13, 0x15, 0x19, 0x11])
    dict["1"] = Symbol(rawValue: [0x00, 0x41, 0xFF, 0x01])
    dict["2"] = Symbol(rawValue: [0x43, 0x85, 0x89, 0x91, 0x61])
    dict["3"] = Symbol(rawValue: [0x42, 0x81, 0x91, 0x91, 0x6E])
    dict["4"] = Symbol(rawValue: [0x18, 0x28, 0x48, 0xFF, 0x08])
    dict["5"] = Symbol(rawValue: [0xF2, 0x91, 0x91, 0x91, 0x8E])
    dict["6"] = Symbol(rawValue: [0x1E, 0x29, 0x49, 0x89, 0x86])
    dict["7"] = Symbol(rawValue: [0x80, 0x8F, 0x90, 0xA0, 0xC0])
    dict["8"] = Symbol(rawValue: [0x6E, 0x91, 0x91, 0x91, 0x6E])
    dict["9"] = Symbol(rawValue: [0x70, 0x89, 0x89, 0x8A, 0x7C])
    dict["?"] = Symbol(rawValue: [0x60, 0x80, 0x8D, 0x90, 0x60])
    dict["!"] = Symbol(rawValue: [0x00, 0xFD])
    dict["0"] = Symbol(rawValue: [0x7E, 0x89, 0x91, 0xA1, 0x7E])
    dict[" "] = Symbol(rawValue: [0x00, 0x00])
    self.table = dict
  }
  
  public static let ghost = Symbol(rawValue: [0x7F, 0x84, 0xA7, 0x84, 0xA7, 0x84, 0x7F, 0x00])
  public static let pacman = Symbol(rawValue: [0x3C, 0x42, 0x81, 0xA1, 0x89, 0x95, 0xA5, 0x42])
}
