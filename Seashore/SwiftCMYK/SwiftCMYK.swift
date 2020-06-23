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
		return NSLocalizedString("groupName", bundle: Bundle(for: Swift.type(of: self)), value: "Color Effect", comment: "Group Name")
	}
	
	public var canReapply: Bool {
		return true
	}
	
	public var type: SeaPluginType {
		return .basic
	}
	
	public func run() {
		let pluginData = seaPlugins!.data
		pluginData.overlayOpacity = 255
		pluginData.overlayBehaviour = .replacing
		let selection = pluginData.selection
		let width = pluginData.width
		let data = pluginData.data
		let overlay = pluginData.overlay
		let replace = pluginData.replace
		let channel = pluginData.channel
		
		guard let srcProf = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile.takeUnretainedValue()).takeRetainedValue(),
			  let destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile.takeUnretainedValue()).takeRetainedValue() else {
				return
		}
		// TODO: Hey Apple! Audit your ColorSync API for Swift!
		let profSeq: [[String: Any]] = [
			[kColorSyncProfile.takeUnretainedValue() as String: srcProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as String,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformDeviceToPCS.takeUnretainedValue() as String],
			
			[kColorSyncProfile.takeUnretainedValue() as String: destProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as String,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformPCSToPCS.takeUnretainedValue() as String],
			
			[kColorSyncProfile.takeUnretainedValue() as String: srcProf,
				kColorSyncRenderingIntent.takeUnretainedValue() as String: kColorSyncRenderingIntentPerceptual.takeUnretainedValue() as String,
				kColorSyncTransformTag.takeUnretainedValue() as String: kColorSyncTransformPCSToDevice.takeUnretainedValue() as String]
		]
		
		guard let cw = ColorSyncTransformCreate(profSeq as NSArray, nil) else {
			return
		}
		
		for j in selection.minY ..< selection.maxY {
			let pos = j * width + selection.origin.x;
			
			var srcLayout: ColorSyncDataLayout = ColorSyncDataLayout(kColorSyncByteOrderDefault);
			let srcDepth = kColorSync8BitInteger;
			var srcRowBytes: Int
			var srcBytes: UnsafeMutableRawPointer? = nil
			guard let dstBytes = UnsafeMutableRawPointer(overlay?.advanced(by: Int(pos) * 4)) else {
				return
			}
			
			if channel == .primary {
				srcBytes = UnsafeMutableRawPointer(data?.advanced(by: Int(pos) * 3))
				srcRowBytes = Int(selection.size.width) * 3;
				srcLayout |= kColorSyncAlphaNone.rawValue;
			} else {
				srcBytes = UnsafeMutableRawPointer(data?.advanced(by: Int(pos) * 4))
				srcRowBytes = Int(selection.size.width) * 4;
				srcLayout |= kColorSyncAlphaLast.rawValue;
			}
			
			guard let srcBytes2 = srcBytes else {
				return
			}
			ColorSyncTransformConvert(cw, Int(selection.size.width), 1, dstBytes, kColorSync8BitInteger, srcLayout, srcRowBytes, srcBytes2, srcDepth, srcLayout, srcRowBytes, nil);
			
			for i in (0..<selection.size.width).reversed() {
				if channel == .primary {
					overlay?[Int(pos + i) * 4 + 3] = 255;
				} else {
					overlay?[Int(pos + i) * 4 + 3] = data![Int(pos + i) * 4 + 3];
				}
				replace?[Int(pos + i)] = 255;
			}
		}
		
		pluginData.apply()
	}
	
	public func reapply() {
		run()
	}

	public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if let pluginData = seaPlugins?.data {
			if pluginData.channel == .alpha {
				return false
			}
			
			if pluginData.spp == 2 {
				return false
			}
		}

		return true
	}
}
