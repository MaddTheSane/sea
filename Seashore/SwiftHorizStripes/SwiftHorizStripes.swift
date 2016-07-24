//
//  SwiftHorizStripes.swift
//  Seashore
//
//  Created by C.W. Betts on 7/13/16.
//
//

import Cocoa
import SeashoreKit


private func specmod<A where A: SignedIntegerType>(a: A, _ b: A) -> A {
	if (a < 0) {
		return b + a % b;
	} else {
		return a % b;
	}
}

///Clamps a variable between `minimum` and `maximum`.
///
///If `minimum` is greater than `maximum`, the original value is returned.
private func clamp<X: Comparable>(value: X, minimum: X, maximum: X) -> X {
	if minimum > maximum {
		return value
	}
	return max(min(value, maximum), minimum)
}

public final class SwiftHorizStripes: SSKPlugin {
	public override func type() -> Int32 {
		return kPointPlugin
	}
	
	public override var points: Int32 {
		return 2
	}
	
	public override var name: String {
		return NSBundle(forClass: self.dynamicType).localizedStringForKey("name", value: "HorizStripes", table: nil)
	}
	
	public override var groupName: String {
		return NSBundle(forClass: self.dynamicType).localizedStringForKey("groupName", value: "Generate", table: nil)
	}
	
	public override var instruction: String {
		return NSBundle(forClass: self.dynamicType).localizedStringForKey("instruction", value: "Needs localization.", table: nil)
	}

	public override var sanity: String {
		return "Seashore Approved (Bobo)"
	}
	
	public override func run()  {
		var backColorAlpha = [UInt8](count: 4, repeatedValue: 0)
		var foreColorAlpha = [UInt8](count: 4, repeatedValue: 0)
		let pluginData = seaPlugins.data
		
		// Get plug-in data
		let width = pluginData.width
		let spp = pluginData.spp
		let selection = pluginData.selection
		let point = pluginData.point(0)
		let apoint = pluginData.point(1)
		let amount = abs(apoint.y - point.y);
		let overlay = pluginData.overlay
		
		// Prepare for drawing
		pluginData.overlayOpacity = 255
		pluginData.overlayBehaviour = .NormalBehaviour
		
		// Get colors
		if spp == 4 {
			foreColorAlpha[0] = UInt8(clamp(pluginData.foreColor(true).redComponent * 255, minimum: 0, maximum: 255))
			foreColorAlpha[1] = UInt8(clamp(pluginData.foreColor(true).greenComponent * 255, minimum: 0, maximum: 255))
			foreColorAlpha[2] = UInt8(clamp(pluginData.foreColor(true).blueComponent * 255, minimum: 0, maximum: 255))
			foreColorAlpha[3] = UInt8(clamp(pluginData.foreColor(true).alphaComponent * 255, minimum: 0, maximum: 255))
			
			backColorAlpha[0] = UInt8(clamp(pluginData.backColor(true).redComponent * 255, minimum: 0, maximum: 255))
			backColorAlpha[1] = UInt8(clamp(pluginData.backColor(true).greenComponent * 255, minimum: 0, maximum: 255))
			backColorAlpha[2] = UInt8(clamp(pluginData.backColor(true).blueComponent * 255, minimum: 0, maximum: 255))
			backColorAlpha[3] = UInt8(clamp(pluginData.backColor(true).alphaComponent * 255, minimum: 0, maximum: 255))
		} else {
			foreColorAlpha[0] = UInt8(clamp(pluginData.foreColor(true).whiteComponent * 255, minimum: 0, maximum: 255))
			foreColorAlpha[1] = UInt8(clamp(pluginData.foreColor(true).alphaComponent * 255, minimum: 0, maximum: 255))
			
			backColorAlpha[0] = UInt8(clamp(pluginData.backColor(true).whiteComponent * 255, minimum: 0, maximum: 255))
			backColorAlpha[1] = UInt8(clamp(pluginData.backColor(true).alphaComponent * 255, minimum: 0, maximum: 255))
		}
		
		// Run checkboard
		for j in selection.origin.y..<(selection.origin.y + selection.size.height) {
			for i in selection.origin.x..<(selection.origin.x + selection.size.width) {
				let pos = j * width + i;
				
				let black: Bool = (specmod(j - point.y, amount * 2) < amount);
				for _ in 0..<spp {
					if black {
						memcpy(&(overlay[Int(pos * spp)]), foreColorAlpha, Int(spp));
					} else {
						memcpy(&(overlay[Int(pos * spp)]), backColorAlpha, Int(spp));
					}
				}
				
			}
		}
		
		// Apply the change and record success
		pluginData.apply()
		success = true;
	}
	
	public override func validateMenuItem(menuItem: AnyObject!) -> Bool {
		return true
	}
}
