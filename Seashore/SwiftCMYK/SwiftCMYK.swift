//
//  SwiftCMYK.swift
//  Seashore
//
//  Created by C.W. Betts on 7/25/16.
//
//

import Cocoa
import SeashoreKit

final public class CMYK: NSObject, SeaPluginClass {
	weak var seaPlugins: SeaPlugins?
	public required init(manager: SeaPlugins) {
		seaPlugins = manager
	}
	
	public var name: String {
		return "SwiftCMYK"
	}
	
	public var groupName: String {
		return NSBundle(forClass: self.dynamicType).localizedStringForKey("groupName", value: "Color Effect", table: nil)
	}
	
	public var canReapply: Bool {
		return true
	}
	
	public var type: Int32 {
		return kBasicPlugin
	}
	
	public func run() {
		let pluginData = seaPlugins!.data
		pluginData.overlayOpacity = 255
		pluginData.overlayBehaviour = .Replacing
		let selection = pluginData.selection
		let width = pluginData.width
		let data = pluginData.data
		let overlay = pluginData.overlay
		let replace = pluginData.replace
		let channel = pluginData.channel
		
		let srcProf = ColorSyncProfileCreateWithDisplayID(0).takeRetainedValue()
		let destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile.takeUnretainedValue()).takeRetainedValue()
		// TODO: Hey Apple! Audit your ColorSync API for Swift!
		let profSeq: [[String:AnyObject]] = [
			[kColorSyncProfile.takeUnretainedValue() as String: srcProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as NSString,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformDeviceToPCS.takeUnretainedValue() as NSString],
			
			[kColorSyncProfile.takeUnretainedValue() as String: destProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as NSString,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformPCSToPCS.takeUnretainedValue() as NSString],
			
			[kColorSyncProfile.takeUnretainedValue() as String: srcProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as NSString,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformPCSToDevice.takeUnretainedValue() as NSString]
		]
		
		let cw = ColorSyncTransformCreate(profSeq, nil).takeRetainedValue()
		
		for j in selection.origin.y..<(selection.origin.y + selection.size.height)  {
			let pos = j * width + selection.origin.x;
			
			var srcLayout: ColorSyncDataLayout = ColorSyncDataLayout(kColorSyncByteOrderDefault);
			let srcDepth = kColorSync8BitInteger;
			var srcRowBytes: Int
			var srcBytes: UnsafeMutablePointer<Void> = nil
			let dstBytes = UnsafeMutablePointer<Void>(overlay.advancedBy(Int(pos) * 4))
			
			if channel == .Primary {
				srcBytes = UnsafeMutablePointer<Void>(data.advancedBy(Int(pos) * 3))
				srcRowBytes = Int(selection.size.width) * 3;
				srcLayout |= kColorSyncAlphaNone.rawValue;
			} else {
				srcBytes = UnsafeMutablePointer<Void>(data.advancedBy(Int(pos) * 4))
				srcRowBytes = Int(selection.size.width) * 4;
				srcLayout |= kColorSyncAlphaLast.rawValue;
			}
			
			ColorSyncTransformConvert(cw, Int(selection.size.width), 1, dstBytes, kColorSync8BitInteger, srcLayout, srcRowBytes, srcBytes, srcDepth, srcLayout, srcRowBytes, nil);
			
			for i in (0..<selection.size.width).reverse() {
				if channel == .Primary {
					overlay[Int(pos + i) * 4 + 3] = 255;
				} else {
					overlay[Int(pos + i) * 4 + 3] = data[Int(pos + i) * 4 + 3];
				}
				replace[Int(pos + i)] = 255;
			}
		}
		
		pluginData.apply()
	}
	
	public func reapply() {
		run()
	}

	public override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
		if let pluginData = seaPlugins?.data {
			if pluginData.channel == .Alpha {
				return false
			}
			
			if pluginData.spp == 2 {
				return false
			}
		}

		return true
	}
}
