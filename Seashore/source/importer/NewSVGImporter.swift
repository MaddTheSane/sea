//
//  NewSVGImporter.swift
//  Seashore
//
//  Created by C.W. Betts on 7/26/16.
//
//

import Cocoa
import GIMPCore
import PocketSVG.SVGLayer

private class FlippedView: NSView {
	override var isFlipped: Bool {
		return true
	}
}

public final class SVGImporter: NSObject, SeaImporter {
	typealias ImporterErrors = SVGImporterErrors
	
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
	
	
	@objc(addToDocument:contentsOfURL:error:)
	public func add(to doc: SeaDocument, contentsOf path: URL) throws {
		var tmpNibArr: NSArray?
		Bundle.main.loadNibNamed("SVGContent", owner: self, topLevelObjects: &tmpNibArr)
		if let tmpNibArr = tmpNibArr {
			nibArr = tmpNibArr
		}
		let layer = try loadSVGLayer(to: doc, contentsOf: path)
		
		// Rename the layer
		layer.name = path.deletingPathExtension().lastPathComponent
		
		// Add the layer
		doc.contents.addLayerObject(layer)
		
		// Position the new layer correctly
		doc.operations!.seaAlignment.centerLayerHorizontally(nil)
		doc.operations!.seaAlignment.centerLayerVertically(nil)
	}
	
	@objc(loadSVGLayer:contentsOfURL:error:)
	public func loadSVGLayer(to doc: SeaDocument, contentsOf path: URL) throws -> SeaLayer {
		//[NSBundle loadNibNamed:@"SVGContent" owner:self]
		let svg = SVGLayer(contentsOf: path)
		guard svg.paths.count != 0 else {
			throw ImporterErrors(.couldNotLoadSVG)
		}
		scalePanel.center()
		trueSize = IntSize(svg.preferredFrameSize())
		size = trueSize
		sizeLabel.stringValue = "\(size.width) × \(size.height)"
		scaleSlider.integerValue = 2
		NSApp.runModal(for: scalePanel)
		scalePanel.orderOut(self)
		
		guard let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: Int(size.width) * 4, bitsPerPixel: 32) else {
			throw ImporterErrors(.unableToCreateBitmap)
		}
		let view = FlippedView()
		view.layer = svg
		svg.frame = NSRect(origin: .zero, size: size.nsSize)
		view.frame = svg.frame
		svg.setNeedsDisplay()
		svg.isGeometryFlipped = true
		
		guard let ctx = NSGraphicsContext(bitmapImageRep: imageRep) else {
			throw ImporterErrors(.unableToCreateBitmap)
		}
		view.displayIgnoringOpacity(svg.frame, in: ctx)
		guard let cocoaLayer = CocoaLayer(imageRep: imageRep, document: doc, spp: 4) else {
			throw ImporterErrors(.unableToCreateLayer)
		}
		return cocoaLayer
	}
	
	/// Closes the current modal dialog.
	@IBAction public func endPanel(_ sender: Any?) {
		NSApp.stopModal()
	}
	
	/// Updates the document's expected size.
	@IBAction func update(_ sender: AnyObject?) {
		var factor: Double
		
		switch scaleSlider.integerValue {
		case 0:
			factor = 0.5
			
		case 1:
			factor = 0.75
			
		case 2:
			factor = 1.0
			
		case 3:
			factor = 1.5
			
		case 4:
			factor = 2.0
			
		case 5:
			factor = 3.75
			
		case 6:
			factor = 5.0
			
		case 7:
			factor = 7.5
			
		case 8:
			factor = 10.0
			
		case 9:
			factor = 25.0
			
		case 10:
			factor = 50.0
			
		default:
			factor = 1.0
		}
		
		size.width = Int32(Double(trueSize.width) * factor);
		size.height = Int32(Double(trueSize.height) * factor)
		
		sizeLabel.stringValue = "\(size.width) × \(size.height)"
	}
}
