//
//  NewSVGImporter.swift
//  Seashore
//
//  Created by C.W. Betts on 7/26/16.
//
//

import Cocoa
import SeashoreKit

final class NewSVGImporter: NSObject {
	@objc enum NewSVGImporterErrors: Int, ErrorType {
		case CouldNotFindBundle = -1
		case CouldNotLoadBundle = -2
		case CouldNotLoadSVG = -3
		case UnableToGenerateTIFF = -4
		case UnableToCreateBitmap = -5
		case UnableToCreateLayer = -6
		
		var _code: Int {
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
	
	@objc(addToDocument:contentsOfURL:error:) func add(to doc: SeaDocument, contentsOf path: NSURL) throws {
		trueSize = getDocumentSize(path.fileSystemRepresentation)
		size = trueSize
		let fm = NSFileManager.defaultManager()
		
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
		
		func getImageRep() throws -> NSImageRep {
			var aClass: AnyClass? = NSClassFromString("SVGImageRep")
			if aClass == nil {
				guard let bundURL = NSBundle.mainBundle().builtInPlugInsURL?.URLByAppendingPathComponent("SVGImageRep.bundle") else {
					throw NewSVGImporterErrors.CouldNotFindBundle
				}
				guard let aBund = NSBundle(URL: bundURL) where aBund.load() else {
					throw NewSVGImporterErrors.CouldNotLoadBundle
				}
				aClass = NSClassFromString("SVGImageRep")
			}
			
			guard let toRet = (aClass as? NSImageRep.Type)?.imageRepsWithContentsOfURL(path)?.first else {
				throw NewSVGImporterErrors.CouldNotLoadSVG
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
			throw NewSVGImporterErrors.UnableToGenerateTIFF
		}
		guard let bitRep = NSBitmapImageRep.imageRepsWithData(tiffData).first as? NSBitmapImageRep else {
			throw NewSVGImporterErrors.UnableToCreateBitmap
		}
		
		// Create the layer
		guard let layer = CocoaLayer(imageRep: bitRep, document: doc, spp:doc.contents.samplesPerPixel) else {
			throw NewSVGImporterErrors.UnableToCreateLayer
		}
		
		// Rename the layer
		layer.name = (path.lastPathComponent! as NSString).stringByDeletingPathExtension
		
		// Add the layer
		doc.contents.addLayerObject(layer)
		
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
