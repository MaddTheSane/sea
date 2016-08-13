//
//  NewSVGImporter.swift
//  Seashore
//
//  Created by C.W. Betts on 7/26/16.
//
//

import Cocoa
import GIMPCore

public final class SVGImporter: NSObject {
	@objc public enum ImporterErrors: Int, ErrorType {
		case CouldNotFindBundle = -1
		case CouldNotLoadBundle = -2
		case CouldNotLoadSVG = -3
		case UnableToGenerateTIFF = -4
		case UnableToCreateBitmap = -5
		case UnableToCreateLayer = -6
		
		case CouldNotFindApp = -7
		case CouldNotLoadConvertedPNG = -8

		public var _code: Int {
			return rawValue
		}
		
		#if false
		var _domain: String {
			return "Seashore.NewSVGImporter.Errors"
		}
		
		var _NSErrorDomain: String {
			return "Seashore.NewSVGImporter.Errors"
		}
		#endif
	}
	
	
	/// The length warning panel
	@IBOutlet weak var waitPanel: NSPanel!

	/// The spinner to update
	@IBOutlet weak var spinner: NSProgressIndicator!

	/// The scaling panel
	@IBOutlet weak var scalePanel: NSPanel!

	/// The slider indicating the extent of scaling
	@IBOutlet weak var scaleSlider: NSSlider!

	/// A label indicating the document's expected size
	@IBOutlet weak var sizeLabel: NSTextField!

	/// The document's actual size
	var trueSize = IntSize()
	/// The document's scaled size
	var size = IntSize()
	
	private var nibArr = NSArray()
	
	private func getSVGFromSVGImporterApp(url url: NSURL, to doc: SeaDocument) throws {
		let fm = NSFileManager.defaultManager()
		let pathOut: String

		let importerPath: String? = {
			guard let bundURL = NSBundle.mainBundle().builtInPlugInsURL?.URLByAppendingPathComponent("SVGImporter.app"),
			importerBundle = NSBundle(URL: bundURL) else {
				return nil
			}
			
			if let importerInternalPath = importerBundle.executablePath {
				return importerInternalPath
			}
			
			return nil
		}()
		
		if let importerPath = importerPath where fm.fileExistsAtPath(importerPath) {
			let args: [String]
			if !fm.fileExistsAtPath("/tmp/seaimport") {
				try fm.createDirectoryAtPath("/tmp/seaimport", withIntermediateDirectories: true, attributes: nil)
			}
			let pathIn = url.path!
			pathOut = "/tmp/seaimport/\((url.lastPathComponent! as NSString).stringByDeletingPathExtension).png"
			if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
				let widthArg = "\(size.width)"
				let heightArg = "\(size.height)"
				args = [pathIn, pathOut, widthArg, heightArg]
			} else {
				args = [pathIn, pathOut]
			}
			waitPanel.center()
			waitPanel.makeKeyAndOrderFront(self)
			let task = NSTask.launchedTaskWithLaunchPath(importerPath, arguments: args)
			spinner.startAnimation(self)
			while task.running {
				NSThread.sleepUntilDate(NSDate(timeIntervalSinceNow: 0.5))
			}
			spinner.stopAnimation(self)
			waitPanel.orderOut(self)
		} else {
			throw ImporterErrors.CouldNotFindApp
		}
		
		// Open the image
		guard let image = NSImage(byReferencingFile: pathOut)  else {
			throw ImporterErrors.CouldNotLoadConvertedPNG
		}
		
		// Form a bitmap representation of the file at the specified path
		func getImgRep() -> NSBitmapImageRep? {
			var imageRep: NSImageRep?
			if let imgRep = image.representations.first {
				if let imgBitRep = imgRep as? NSBitmapImageRep {
					imageRep = imgBitRep
				} else if let tiffData = image.TIFFRepresentation {
					imageRep = NSBitmapImageRep.imageRepsWithData(tiffData).first
				}
			}
			return imageRep as? NSBitmapImageRep
		}
		guard let imgBitmapRep = getImgRep() else {
			throw ImporterErrors.UnableToCreateBitmap
		}
		
		// Create the layer
		guard let layer = CocoaLayer(imageRep: imgBitmapRep, document: doc, spp: doc.contents.samplesPerPixel) else {
			throw ImporterErrors.UnableToCreateLayer
		}
		
		// Rename the layer
		layer.name = (url.lastPathComponent! as NSString).stringByDeletingPathExtension
		
		// Add the layer
		doc.contents.addLayerObject(layer)
		
		// Now forget the NSImage
	}
	
	private func getSVGFromSVGImageRep(url url: NSURL, to doc: SeaDocument) throws {
		func getImageRep() throws -> NSImageRep {
			var aClass: AnyClass? = NSClassFromString("SVGImageRep")
			if aClass == nil {
				guard let bundURL = NSBundle.mainBundle().builtInPlugInsURL?.URLByAppendingPathComponent("SVGImageRep.bundle") where bundURL.checkResourceIsReachableAndReturnError(nil) else {
					throw ImporterErrors.CouldNotFindBundle
				}
				guard let aBund = NSBundle(URL: bundURL) where aBund.load() else {
					throw ImporterErrors.CouldNotLoadBundle
				}
				aClass = NSClassFromString("SVGImageRep")
			}
			
			guard let toRet = (aClass as? NSImageRep.Type)?.imageRepsWithContentsOfURL(url)?.first else {
				throw ImporterErrors.CouldNotLoadSVG
			}
			return toRet
		}
		let svgRep = try getImageRep()
		let image = NSImage()
		image.addRepresentation(svgRep)
		if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
			image.size = size.NSSize
		}
		guard let tiffData = image.TIFFRepresentation else {
			throw ImporterErrors.UnableToGenerateTIFF
		}
		guard let bitRep = NSBitmapImageRep.imageRepsWithData(tiffData).first as? NSBitmapImageRep else {
			throw ImporterErrors.UnableToCreateBitmap
		}
		
		// Create the layer
		guard let layer = CocoaLayer(imageRep: bitRep, document: doc, spp:doc.contents.samplesPerPixel) else {
			throw ImporterErrors.UnableToCreateLayer
		}
		
		// Rename the layer
		layer.name = (url.lastPathComponent! as NSString).stringByDeletingPathExtension
		
		// Add the layer
		doc.contents.addLayerObject(layer)
	}
	
	@objc(addToDocument:contentsOfURL:error:) public func add(to doc: SeaDocument, contentsOf path: NSURL) throws {
		trueSize = getDocumentSize(path.fileSystemRepresentation)
		size = trueSize
		
		var tmpNibArr: NSArray?
		NSBundle.mainBundle().loadNibNamed("SVGContent", owner: self, topLevelObjects: &tmpNibArr)
		if let tmpNibArr = tmpNibArr {
			nibArr = tmpNibArr
		}
		
		scalePanel.center()
		sizeLabel.stringValue = "\(size.width) x \(size.height)"
		scaleSlider.integerValue = 2
		NSApp.runModalForWindow(scalePanel)
		scalePanel.orderOut(self)
		
		do {
			if NSUserDefaults.standardUserDefaults().boolForKey(SeaUseOldSVGImporterKey) {
				try getSVGFromSVGImporterApp(url: path, to: doc)
			} else {
				do {
					try getSVGFromSVGImageRep(url: path, to: doc)
				} catch ImporterErrors.CouldNotFindBundle {
					try getSVGFromSVGImporterApp(url: path, to: doc)
				} catch {
					throw error
				}
			}
		} catch ImporterErrors.CouldNotFindApp {
			SeaController.seaWarning().addMessage(NSLocalizedString("SVG message", value: "Seashore is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on Seashore's website.", comment: "SVG message"), level: .High)
			throw ImporterErrors.CouldNotFindApp
		} catch {
			throw error
		}
		
		// Position the new layer correctly
		doc.operations.seaAlignment.centerLayerHorizontally(nil)
		doc.operations.seaAlignment.centerLayerVertically(nil)
	}
	
	/// Closes the current modal dialog.
	@IBAction func endPanel(sender: AnyObject?) {
		NSApp.stopModal()
	}
	
	/// Updates the document's expected size.
	@IBAction func update(sender: AnyObject?) {
		var factor: Double
		
		switch (scaleSlider.intValue) {
		case 0:
			factor = 0.5;
			break;
		case 1:
			factor = 0.75;
			break;
		case 2:
			factor = 1.0;
			break;
		case 3:
			factor = 1.5;
			break;
		case 4:
			factor = 2.0;
			break;
		case 5:
			factor = 3.75;
			break;
		case 6:
			factor = 5.0;
			break;
		case 7:
			factor = 7.5;
			break;
		case 8:
			factor = 10.0;
			break;
		case 9:
			factor = 25.0;
			break;
		case 10:
			factor = 50.0;
			break;
		default:
			factor = 1.0;
			break;
		}
		
		size.width = Int32(Double(trueSize.width) * factor);
		size.height = Int32(Double(trueSize.height) * factor)
		
		sizeLabel.stringValue = "\(size.width) x \(size.height)"
	}
}
