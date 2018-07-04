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
	@objc public enum ImporterErrors: Int, Error {
		case couldNotFindBundle = -1
		case couldNotLoadBundle = -2
		case couldNotLoadSVG = -3
		case unableToGenerateTIFF = -4
		case unableToCreateBitmap = -5
		case unableToCreateLayer = -6
		
		case couldNotFindApp = -7
		case couldNotLoadConvertedPNG = -8

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
	
	fileprivate var nibArr = NSArray()
	
	fileprivate func getSVGFromSVGImporterApp(url: URL, to doc: SeaDocument) throws {
		let fm = FileManager.default
		let pathOut: String

		let importerPath: String? = {
			guard let bundURL = Bundle.main.builtInPlugInsURL?.appendingPathComponent("SVGImporter.app"),
			let importerBundle = Bundle(url: bundURL) else {
				return nil
			}
			
			if let importerInternalPath = importerBundle.executablePath {
				return importerInternalPath
			}
			
			return nil
		}()
		
		if let importerPath = importerPath , fm.fileExists(atPath: importerPath) {
			let args: [String]
			if !fm.fileExists(atPath: "/tmp/seaimport") {
				try fm.createDirectory(atPath: "/tmp/seaimport", withIntermediateDirectories: true, attributes: nil)
			}
			let pathIn = url.path
			pathOut = "/tmp/seaimport/\((url.lastPathComponent as NSString).deletingPathExtension).png"
			if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
				let widthArg = "\(size.width)"
				let heightArg = "\(size.height)"
				args = [pathIn, pathOut, widthArg, heightArg]
			} else {
				args = [pathIn, pathOut]
			}
			waitPanel.center()
			waitPanel.makeKeyAndOrderFront(self)
			let task = Process.launchedProcess(launchPath: importerPath, arguments: args)
			spinner.startAnimation(self)
			while task.isRunning {
				Thread.sleep(until: Date(timeIntervalSinceNow: 0.5))
			}
			spinner.stopAnimation(self)
			waitPanel.orderOut(self)
		} else {
			throw ImporterErrors.couldNotFindApp
		}
		
		// Open the image
		guard let image = NSImage(byReferencingFile: pathOut)  else {
			throw ImporterErrors.couldNotLoadConvertedPNG
		}
		
		// Form a bitmap representation of the file at the specified path
		func getImgRep() -> NSBitmapImageRep? {
			var imageRep: NSImageRep?
			if let imgRep = image.representations.first {
				if let imgBitRep = imgRep as? NSBitmapImageRep {
					imageRep = imgBitRep
				} else if let tiffData = image.tiffRepresentation {
					imageRep = NSBitmapImageRep.imageReps(with: tiffData).first
				}
			}
			return imageRep as? NSBitmapImageRep
		}
		guard let imgBitmapRep = getImgRep() else {
			throw ImporterErrors.unableToCreateBitmap
		}
		
		// Create the layer
		guard let layer = CocoaLayer(imageRep: imgBitmapRep, document: doc, spp: doc.contents.samplesPerPixel) else {
			throw ImporterErrors.unableToCreateLayer
		}
		
		// Rename the layer
		layer.name = (url.lastPathComponent as NSString).deletingPathExtension
		
		// Add the layer
		doc.contents.addLayerObject(layer)
		
		// Now forget the NSImage
	}
	
	fileprivate func getSVGFromSVGImageRep(url: URL, to doc: SeaDocument) throws {
		func getImageRep() throws -> NSImageRep {
			var aClass: AnyClass? = NSClassFromString("SVGImageRep")
			if aClass == nil {
				guard let bundURL = Bundle.main.builtInPlugInsURL?.appendingPathComponent("SVGImageRep.bundle") , (bundURL as NSURL).checkResourceIsReachableAndReturnError(nil) else {
					throw ImporterErrors.couldNotFindBundle
				}
				guard let aBund = Bundle(url: bundURL) , aBund.load() else {
					throw ImporterErrors.couldNotLoadBundle
				}
				aClass = NSClassFromString("SVGImageRep")
			}
			
			guard let toRet = (aClass as? NSImageRep.Type)?.imageReps(withContentsOf: url)?.first else {
				throw ImporterErrors.couldNotLoadSVG
			}
			return toRet
		}
		let svgRep = try getImageRep()
		let image = NSImage()
		image.addRepresentation(svgRep)
		if size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize {
			image.size = size.nsSize
		}
		guard let tiffData = image.tiffRepresentation else {
			throw ImporterErrors.unableToGenerateTIFF
		}
		guard let bitRep = NSBitmapImageRep.imageReps(with: tiffData).first as? NSBitmapImageRep else {
			throw ImporterErrors.unableToCreateBitmap
		}
		
		// Create the layer
		guard let layer = CocoaLayer(imageRep: bitRep, document: doc, spp:doc.contents.samplesPerPixel) else {
			throw ImporterErrors.unableToCreateLayer
		}
		
		// Rename the layer
		layer.name = (url.lastPathComponent as NSString).deletingPathExtension
		
		// Add the layer
		doc.contents.addLayerObject(layer)
	}
	
	@objc(addToDocument:contentsOfURL:error:)
	public func add(to doc: SeaDocument, contentsOf path: URL) throws {
		trueSize = path.withUnsafeFileSystemRepresentation { (fileRef) -> IntSize in
			return getDocumentSize(fileRef)
		}
		size = trueSize
		
		var tmpNibArr: NSArray?
		Bundle.main.loadNibNamed(NSNib.Name("SVGContent"), owner: self, topLevelObjects: &tmpNibArr)
		if let tmpNibArr = tmpNibArr {
			nibArr = tmpNibArr
		}
		
		scalePanel.center()
		sizeLabel.stringValue = "\(size.width) x \(size.height)"
		scaleSlider.integerValue = 2
		NSApp.runModal(for: scalePanel)
		scalePanel.orderOut(self)
		
		do {
			if UserDefaults.standard.bool(forKey: SeaUseOldSVGImporterKey) {
				try getSVGFromSVGImporterApp(url: path, to: doc)
			} else {
				do {
					try getSVGFromSVGImageRep(url: path, to: doc)
				} catch ImporterErrors.couldNotFindBundle {
					try getSVGFromSVGImporterApp(url: path, to: doc)
				} catch {
					throw error
				}
			}
		} catch ImporterErrors.couldNotFindApp {
			SeaController.seaWarning.addMessage(NSLocalizedString("SVG message", value: "Seashore is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on Seashore's website.", comment: "SVG message"), level: .high)
			throw ImporterErrors.couldNotFindApp
		} catch {
			throw error
		}
		
		// Position the new layer correctly
		doc.operations!.seaAlignment.centerLayerHorizontally(nil)
		doc.operations!.seaAlignment.centerLayerVertically(nil)
	}
	
	/// Closes the current modal dialog.
	@IBAction func endPanel(_ sender: AnyObject?) {
		NSApp.stopModal()
	}
	
	/// Updates the document's expected size.
	@IBAction func update(_ sender: AnyObject?) {
		var factor: Double
		
		switch scaleSlider.intValue {
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
		
		sizeLabel.stringValue = "\(size.width) x \(size.height)"
	}
}
