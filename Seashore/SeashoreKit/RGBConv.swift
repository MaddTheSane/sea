//
//  RGBConv.swift
//  Seashore
//
//  Created by C.W. Betts on 10/2/16.
//
//

import Foundation

public final class ColorConversion {
	public static func RGBToHLS(red: Int32, green: Int32, blue: Int32) -> (hue: Int32, lightness: Int32, saturation: Int32) {
		var red1 = red, green1 = green, blue1 = blue
		SeaRGBtoHLS(&red1, &green1, &blue1)
		return (red1, green1, blue1)
	}
	
	public static func HLSToRGB(hue: Int32, lightness: Int32, saturation: Int32) -> (red: Int32, green: Int32, blue: Int32) {
		var hue1 = hue, saturation1 = saturation, lightness1 = lightness
		SeaHLStoRGB(&hue1, &lightness1, &saturation1)
		return (hue1, lightness1, saturation1)
	}
	
	public static func RGBToHSV(red: Int32, green: Int32, blue: Int32) -> (hue: Int32, saturation: Int32, value: Int32) {
		var red1 = red, green1 = green, blue1 = blue
		SeaRGBtoHSV(&red1, &green1, &blue1)
		return (red1, green1, blue1)
	}

	public static func HSVToRGB(hue: Int32, saturation: Int32, value: Int32) -> (red: Int32, green: Int32, blue: Int32) {
		var hue1 = hue, saturation1 = saturation, value1 = value
		SeaHSVtoRGB(&hue1, &saturation1, &value1)
		return (hue1, saturation1, value1)
	}
}

