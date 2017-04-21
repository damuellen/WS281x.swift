![WS281x](https://github.com/uraimo/WS281x.swift/raw/master/logo.png)

*A Swift library for WS2812x/NeoPixel (WS2811,WS2812,WS2812B,WS2813) RGB led strips, rings, sticks, matrices, etc...*

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift3-compatible-4BC51D.svg?style=flat" alt="Swift 3 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/WS281x.swift/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

<p>
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led1.gif" />
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led2.gif" />
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led3.gif" />
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led1.gif" />
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led2.gif" />
<img src="https://github.com/uraimo/SwiftyGPIO/raw/master/images/led3.gif" />
</p>

# Summary

This library simplifies the configuration of series of WS281x leds (WS2811, WS2812, WS281x), sometimes marketed as NeoPixels, regardless of the form in which they are sold: strips, matrices, rings, etc...

You will be able to set the color of individual pixels (with both sequential and matrix coordinates) or set them in bulk with a single call (faster, recommended for smoother animations). Click [here](https://fat.gfycat.com/HospitableFickleJoey.gif) or [here](https://giant.gfycat.com/UltimateAgileBeardeddragon.gif) for two real-time gifs that show what you could do with this library.

## Usage

First of all an hardware note, WS281x leds are 3-pins 5V devices (Vcc,DataIN,GND) but most of the times can tollerate a 3.3V DataIN signal like the one produced by the RaspberryPi (and other ARM boards) gpio pins. If you notice that your leds are flickering or not too bright, you could need a level shifter/converter/translator for you data pin. There are a lot of different ways (with different performance) to translate a 3.3V signal to a 5V one, but the most cost effective way to solve this specific problem is maybe just to buy a simple level converter [like this one from SparkFun](https://www.sparkfun.com/products/12009). It works perfectly and you just need to solder a pin header and you are ready to go.

Now, for the software side, suppose we are using a strip with 60 WS2812B leds, the first thing we need to do is obtain an instance of `PWMOutput` from SwiftyGPIO and use it to initialize the `WS281x` object:

```swift
import SwiftyGPIO
import WS281x

let pwms = SwiftyGPIO.hardwarePWMs(for:.RaspberryPi2)!
let pwm = (pwms[0]?[.P18])!

let numberOfLeds = 60

let w = WS281x(pwm, 
               type: .WS2812B,
               numElements: numberOfLeds)
```

We'll then need to specify the number of leds and the type of the leds we are using (either `.WS2811`, `.WS2812` or `.WS2812B`), the library will use the type to determine the correct signaling timing for these leds.

Let's start clearing all the leds in the strip, setting them with the rgb color `#000000`:

```swift
w.clear()

w.start()
w.wait()
```

Once you are done (or even in a `defer` block) remember to clean up all the temporary PWM settings that were needed for this library with:

```swift
w.cleanup()
```

## Supported Boards

Every board supported by [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) with pattern-based PWM signal generator, at the moment only RaspberryPis.

And to use this library, you'll need Swift 3.x.

The example below will use a RaspberryPi 2 board but you can easily modify the example to use one the the other supported boards, a full working demo projects for the RaspberryPi2 is available in the `Examples` directory.

## Installation

Please refer to the [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) readme for Swift installation instructions.

Once your board runs Swift, if your version support the Swift Package Manager, you can simply add this library as a dependency of your project and compile with `swift build`:

```swift
  let package = Package(
      name: "MyProject",
      dependencies: [
    .Package(url: "https://github.com/uraimo/WS281x.swift.git", majorVersion: 2),
    ...
      ]
      ...
  ) 
```

If SPM is not supported, you'll need to manually download the library and its dependencies: 

    wget https://raw.githubusercontent.com/uraimo/WS281x.swift/master/Sources/WS281x.swift https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/Presets.swift https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/PWM.swift https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/Mailbox.swift  https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SunXi.swift  

And once all the files have been downloaded, create an additional file that will contain the code of your application (e.g. main.swift). When your code is ready, compile it with:

    swiftc *.swift

The compiler will create a **main** executable.

## Frequently Asked Questions

1. How many leds I will be able to control?

The update frequency and the power consumption are the limit factors. As the number of leds grows it takes progressively more time to configure all the connected leds and the power consumption increases. While you can solve the power problem connecting the strip to an external 5V power adapter instead of using the board's 5V/GND pins, the update frequency problem is related to the timing characteristics of the WS281x protocol.

You will be able to use strips with around 400-500 leds without issues, but then you'll start to see progressively diminishing refresh times that could not be appropriate for fast animations. How many leds can the library drive? This depends on how much sequential memory the VideoCore subsystem is able to allocate, there have been reports of people using similar libraries being able to control more than 3000 leds from a RaspberryPi1.

2. Why the library does not appear to work when I'm using the RaspberryPI audio output?

The PWM hardware that this library uses is shared with the audio output, you can't use them both simultaneously.

You could need (ATM, not needed for Raspbian and Ubuntu) to black-list the audio module from `/etc/modprobe.d/snd-blacklist.conf`:

    blacklist snd_bcm2835
