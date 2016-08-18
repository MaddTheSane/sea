//
//  BrushDocument.swift
//  Brushed
//
//  Created by C.W. Betts on 8/13/16.
//
//

import Cocoa

extension String {
	/// Creates a new `String` with the contents of `self`
	/// up to `len` UTF-8 characters long, truncating incomplete
	/// Swift characters at the end.
	private func substringWithLength(utf8 len: Int) -> String {
		let ourUTF = utf8
		guard ourUTF.count > len else {
			return self
		}
		let from8 = ourUTF.startIndex
		let to8 = from8.advancedBy(len, limit: ourUTF.endIndex)
		if let to = String.Index(to8, within: self) {
			return self[startIndex ..< to]
		}
		
		//Oops, we ran into the middle of a code point!
		let stripped = ourUTF[from8 ..< to8]
		var preScalar = String.UnicodeScalarView()
		// Stopping on error because there only error would be cut-off unicode scalars
		transcode(UTF8.self, UTF32.self, stripped.generate(), { preScalar.append(UnicodeScalar($0)) }, stopOnError: true)
		
		return String(preScalar)
	}
}
//#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

private func int_mult(a: UInt8, _ b: UInt8) -> UInt8 {
	let t = Int(a) * Int(b) + 0x80
	return UInt8((((t) >> 8) + (t)) >> 8)
}

class BrushDocument: NSDocument, NSWindowDelegate {
	/// A grayscale mask of the brush
	private var mask: UnsafeMutablePointer<UInt8> = nil
	
	/// A coloured pixmap of the brush (RGBA)
	private var pixmap: UnsafeMutablePointer<UInt8> = nil
	
	// All previous bitmaps (for undos)
	private var undoRecords = [BitmapUndo]()
	private var curUndoPos = 0
	
	/// The spacing between brush strokes
	dynamic var spacing: Int32 = 25 {
		didSet {
			spacingLabel?.stringValue = "Spacing - \(spacing)%"
		}
	}
	
	/// The width and height of the brush
	private var size: (width: Int32, height: Int32) = (0, 0) {
		didSet {
			dimensionsLabel?.stringValue = "\(size.width) x \(size.height)"
		}
	}
	
	// The name of the brush
	dynamic var name = "Untitled";
	
	/// A memory of all past names for the undo manager
	private var pastNames = ["Untitled"];
	
	/// Do we use the pixmap or the mask?
	private var usePixmap = false

	/// The view displaying the brush
	@IBOutlet weak var view: BrushView!
	
	/// The label and slider that present the brush's spacing options
	@IBOutlet weak var spacingLabel: NSTextField!
	/// The label and slider that present the brush's spacing options
	@IBOutlet weak var spacingSlider: NSSlider!
	
	/// The text field for the name
	@IBOutlet weak var nameTextField: NSTextField!
	
	/// The label specifying the brush type (monochrome or full colour)
	@IBOutlet weak var typeButton: NSButton!
	
	/// The label specifying the dimensions of the brush
	@IBOutlet weak var dimensionsLabel: NSTextField!
	
	/// Set the values suitably for a new document
	override init() {
		super.init()
		addToUndoRecords()
		curUndoPos = 0
	}
	
	deinit {
		for record in undoRecords {
			if record.mask != nil {
				free(record.mask)
			}
			if record.pixmap != nil {
				free(record.pixmap)
			}
		}
		undoRecords.removeAll(keepCapacity: false)
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		
		// Set interface elements to match brush settings
		spacingSlider.intValue = spacing == 1 ? 0 : spacing
		spacingLabel.stringValue = "Spacing - \(spacing)%"
		nameTextField.stringValue = name
		if usePixmap {
			typeButton.title = "Type - Full Colour"
		} else {
			typeButton.title = "Type - Monochrome"
		}
		dimensionsLabel.stringValue = "\(size.width) x \(size.height)"
	}
	
	/// Returns an image representing the brush
	var brushImage: NSImage? {
		let tempRep: NSBitmapImageRep
		
		// If we have no width or height in the image return NULL
		if size.width == 0 || size.height == 0 {
			return nil;
		}
		
		// Create the representation
		if (usePixmap) {
			tempRep = NSBitmapImageRep(bitmapDataPlanes: &pixmap, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: Int(size.width) * 4, bitsPerPixel: 32)!
		} else {
			// For whatever reason, Apple deprecated the NSCalibratedBlackColorSpace
			// So we do some rigamarole to get NSCalibratedWhiteColorSpace
			let tempBlack = UnsafeMutableBufferPointer(start: mask, count: Int(size.width * size.height))
			var tmpWhite = tempBlack.map({ (blackComp) -> UInt8 in
				return blackComp ^ 0xff
			})
			let tmpWhitePtr = withUnsafeMutablePointer(&tmpWhite, { (thePtr) -> UnsafeMutablePointer<UnsafeMutablePointer<UInt8>> in
				return UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>(thePtr)
			})
			tempRep = NSBitmapImageRep(bitmapDataPlanes: tmpWhitePtr, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bytesPerRow: Int(size.width), bitsPerPixel: 8)!
		}
		
		// Wrap it up in an NSImage
		let brushImage1 = NSImage(size: NSSize(width: Int(size.width), height: Int(size.height)))
		brushImage1.addRepresentation(tempRep)
		
		return brushImage1;
	}
	
	/// Add current brush image to the undo records
	func addToUndoRecords() {
		// Fill in the new record on the undo stack
		var bmpUndo = BitmapUndo()
		bmpUndo.mask = mask
		bmpUndo.pixmap = pixmap
		bmpUndo.width = size.width
		bmpUndo.height = size.height
		bmpUndo.usePixmap = usePixmap
		undoRecords.append(bmpUndo)
	}

	/// Adjust the image of the brush
	func changeImage(newImage: NSBitmapImageRep!) throws {
		//BOOL invert, isRGB, useAlpha;
		//int i, j, t;
		let spp = newImage.samplesPerPixel
		let data = newImage.bitmapData
		var invert = false
		var isRGB = false
		
		// Check we can handle this image
		guard newImage.bitsPerSample == 8 else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		
		// Fill out isRGB and invert booleans
		if newImage.colorSpaceName == NSCalibratedWhiteColorSpace || newImage.colorSpaceName == NSDeviceWhiteColorSpace {
			isRGB = false; invert = true;
		} else if newImage.colorSpaceName == NSCalibratedRGBColorSpace || newImage.colorSpaceName == NSDeviceRGBColorSpace {
			isRGB = true; invert = false;
		} else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		
		// Fill out useAlpha boolean
		let useAlpha: Bool = {
			if newImage.alpha {
				for i in 0..<(newImage.pixelsWide * newImage.pixelsHigh) {
					if data[i * 2 + 1] != 0xFF {
						return true
					}
				}
			}
			return false
		}()
		
		// Allow the undo
		undoManager?.prepareWithInvocationTarget(self).undoImageTo(curUndoPos)
		
		// Replace with appropriate values
		usePixmap = isRGB;
		size = (Int32(newImage.size.width), Int32(newImage.size.height))
		//width = [newImage size].width; height = [newImage size].height;
		if (!isRGB) {
			mask = UnsafeMutablePointer<UInt8>(malloc(Int(size.width * size.height)))
			for i in 0 ..< Int(size.width * size.height) {
				if (useAlpha) {
					mask[i] = data[i * spp + 1];
				} else {
					mask[i] = (invert) ? 255 &- data[i * spp] : data[i * spp];
				}
			}
			pixmap = UnsafeMutablePointer<UInt8>(malloc(Int(size.width * size.height) * 4))
			for i in 0 ..< Int(size.width * size.height) {
				if (spp == 2) {
					let intVal = int_mult((invert) ? data[i * spp] : 255 &- data[i * spp], data[i * spp + 1])
					pixmap[i * 4] = intVal
					pixmap[i * 4 + 1] = intVal
					pixmap[i * 4 + 2] = intVal
					pixmap[i * 4 + 3] = data[i * spp + 1];
				} else {
					let intVal = (invert) ? data[i * spp] : 255 - data[i * spp];
					pixmap[i * 4] = intVal
					pixmap[i * 4 + 1] = intVal
					pixmap[i * 4 + 2] = intVal
					pixmap[i * 4 + 3] = 255;
				}
			}
		} else {
			mask = UnsafeMutablePointer<UInt8>(malloc(Int(size.width * size.height)))
			for i in 0 ..< Int(size.width * size.height) {
				if (useAlpha) {
					mask[i] = data[i * spp + 3];
				} else {
					mask[i] = 255 - UInt8((Int(data[i * spp]) + Int(data[i * spp + 1]) + Int(data[i * spp + 2])) / 3);
				}
			}
			pixmap = UnsafeMutablePointer<UInt8>(malloc(Int(size.width * size.height) * 4))
			pixmap = UnsafeMutablePointer<UInt8>(memset(pixmap, 255, Int(size.width * size.height) * 4))
			for i in 0 ..< Int(size.width * size.height) {
				for j in 0..<spp {
					pixmap[i * 4 + j] = data[i * spp + j];
				}
			}
		}
		
		// Update everything
		view.needsDisplay = true
		dimensionsLabel.stringValue = "\(size.width) x \(size.height)"
		if usePixmap {
			typeButton.title = "Type - Full Colour"
		} else {
			typeButton.title = "Type - Monochrome"
		}
		
		// Add to undo stack
		addToUndoRecords()
		curUndoPos = undoRecords.count - 1
	}
	
	/// Adjust the name of the brush
	@IBAction func changeName(sender: AnyObject!) {
		// Only do the following if the name has actually changed
		if name != nameTextField.stringValue {
			
			// Allow the undo
			undoManager?.prepareWithInvocationTarget(self).undoNameTo(name)
			
			// Store new name and remember last names for undo
			name = nameTextField.stringValue
			pastNames.append(name)
		}
	}
	
	/// Adjust the brush's spacing
	@IBAction func changeSpacing(sender: AnyObject!) {
		// Allow the undo
		if NSApp.currentEvent?.type == .LeftMouseDown {
			undoManager?.prepareWithInvocationTarget(self).undoSpacingTo(spacing)
		}
		
		// Adjust the spacing
		spacing = (spacingSlider.intValue / 5 * 5 == 0) ? 1 : spacingSlider.intValue / 5 * 5
	}
	
	/// Adjust the brush's type
	@IBAction func changeType(sender: AnyObject!) {
		// Allow the undo
		undoManager?.prepareWithInvocationTarget(self).changeType(sender)
		
		// Make the changes
		usePixmap = !usePixmap;
		view.needsDisplay = true
		if usePixmap {
			typeButton.title = "Type - Full Colour"
		} else {
			typeButton.title = "Type - Monochrome"
		}
	}
	
	/// Loads the given file from disk, returns success
	override func readFromURL(url: NSURL, ofType typeName: String) throws {
		let file = try NSFileHandle(forReadingFromURL: url)
		
		// Set variables appropriately
		undoRecords.removeAll()
		curUndoPos = 0
		
		var header = BrushHeader()
		
		// Read in the header
		var readData = file.readDataOfLength(sizeof(BrushHeader))
		readData.getBytes(&header, length: sizeof(BrushHeader))
		
		// Convert brush header to proper endianess
		header.header_size = header.header_size.bigEndian;
		header.version = header.version.bigEndian;
		header.width = header.width.bigEndian;
		header.height = header.height.bigEndian
		header.bytes = header.bytes.bigEndian
		header.magic_number = header.magic_number.bigEndian
		header.spacing = header.spacing.bigEndian

		// Check version compatibility
		var versionGood = (header.version == 2 && header.magic_number == GBRUSH_MAGIC);
		versionGood = versionGood || (header.version == 1);
		if (!versionGood) {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}

		// Accomodate version 1 brushes (no spacing)
		if (header.version == 1) {
			let offset = file.offsetInFile - 8
			file.seekToFileOffset(offset)
			header.header_size += 8;
			header.spacing = 25;
		}

		// Store information from the header
		size.width = Int32(header.width)
		size.height = Int32(header.height)
		spacing = Int32(header.spacing)

		// Read in brush name
		let nameLen = Int(header.header_size) - sizeof(BrushHeader)
		if (nameLen > 512) {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		if (nameLen > 0) {
			readData = file.readDataOfLength(nameLen)
			if let aStr = String(data: readData, encoding: NSUTF8StringEncoding) {
				//Remove included nil terminator.
				name = aStr.stringByReplacingOccurrencesOfString("\0", withString: "")
			} else {
				name = "Untitled"
			}
		} else {
			name = "Untitled"
		}
		pastNames = [name];
		
		switch header.bytes {
		case 1:
			usePixmap = false
			let tempSize = Int(size.width * size.height)
			mask = UnsafeMutablePointer<UInt8>(malloc(tempSize))
			readData = file.readDataOfLength(tempSize)
			if readData.length < tempSize {
				throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
			}
			readData.getBytes(mask, length: tempSize)
			
		case 4:
			usePixmap = true
			let tempSize = Int(size.width * size.height) * 4
			pixmap = UnsafeMutablePointer<UInt8>(malloc(tempSize))
			if readData.length < tempSize {
				throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
			}
			readData.getBytes(pixmap, length: tempSize)
			premultiplyAlpha(4, pixmap, pixmap, size.width * size.height)
			
		default:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
		}
		
		// Add to the stack
		addToUndoRecords()
		curUndoPos = 0
	}
	
	/// Undoes the image to that which is stored by a given undo record
	func undoImageTo(index: Int) {
		// Allow the redo
		undoManager?.prepareWithInvocationTarget(self).undoImageTo(curUndoPos)
		
		// Restore image from undo record
		pixmap = undoRecords[index].pixmap;
		mask = undoRecords[index].mask;
		size = (undoRecords[index].width, undoRecords[index].height)
		usePixmap = undoRecords[index].usePixmap
		
		// Update everything
		curUndoPos = index;
		view.needsDisplay = true
		if usePixmap {
			typeButton.title = "Type - Full Colour"
		} else {
			typeButton.title = "Type - Monochrome"
		}
	}
	
	/// Undoes the name to a given string
	func undoNameTo(string: String) {
		// Allow the redo
		undoManager?.prepareWithInvocationTarget(self).undoNameTo(name)
		
		// Set the new name
		name = string;
		nameTextField.stringValue = name
	}
	
	/// Undoes the spacing to a given value
	func undoSpacingTo(value: Int32) {
		// Allow the redo
		undoManager?.prepareWithInvocationTarget(self).undoSpacingTo(spacing)
		
		// Adjust the spacing
		spacing = value;
		spacingSlider.intValue = spacing
	}
	
	/// Returns the nib file associated with this class
	override var windowNibName: String? {
		return "BrushDocument"
	}
	
	/// Writes to the given file on disk, returns success
	override func writeToURL(url: NSURL, ofType typeName: String) throws {
		let file = try NSFileHandle(forWritingToURL: url)
		// Set-up the header
		let tempName = name.substringWithLength(utf8: 128)
		// Convert brush header to proper endianess
		var header = BrushHeader()
		header.header_size = UInt32(tempName.utf8.count + 1 + sizeof(BrushHeader)).bigEndian
		header.version = UInt32(2).bigEndian
		header.width = UInt32(size.width).bigEndian
		header.height = UInt32(size.height).bigEndian
		header.bytes = UInt32(usePixmap ? 4 : 1).bigEndian
		header.magic_number = GBRUSH_MAGIC.bigEndian
		header.spacing = UInt32(spacing).bigEndian
		
		// Write the header
		var toWrite = NSData(bytes: &header, length: sizeof(BrushHeader))
		file.writeData(toWrite)
		
		// Write down brush name
		guard var aName = tempName.cStringUsingEncoding(NSUTF8StringEncoding) else {
			throw NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil)
		}
		aName.append(0)
		toWrite = NSData(bytes: &aName, length: aName.count)
		file.writeData(toWrite)
		
		// And then write down the meat of the brush
		if usePixmap {
			let brushData = UnsafeMutablePointer<UInt8>.alloc(Int(size.width * size.height) * 4)
			SeaUnpremultiplyBitmap(4, brushData, pixmap, size.width * size.height);
			toWrite = NSData(bytes: brushData, length: Int(size.width * size.height) * 4)
			brushData.dealloc(Int(size.width * size.height) * 4)
		} else {
			toWrite = NSData(bytes: mask, length: Int(size.width * size.height))
		}
		file.writeData(toWrite)
	}
	
	/// Import a graphic for the brush
	@IBAction func importGraphic(sender: AnyObject!) {
		let openPanel = NSOpenPanel()
		
		openPanel.allowsMultipleSelection = false
		openPanel.prompt = "Import"
		openPanel.allowedFileTypes = [kUTTypeTIFF as String, kUTTypeJPEG as String, kUTTypePNG as String]
		
		openPanel.beginSheetModalForWindow(windowForSheet!) { (result) in
			if result == NSCancelButton {
				return
			}
			do {
				let bmpImg = try BitmapImageRepHelper.bitmapImageRepFromURL(openPanel.URL!)
				try self.changeImage(bmpImg)
			} catch {
				let alert = NSAlert()
				alert.messageText = "Cannot Import"
				alert.informativeText = "Brushed can only import JPEG, PNG and TIFF files with 8-bit RGB channels or an 8-bit Grays channel and optionally an additional alpha channel."
				
				alert.runModal()
			}
		}
	}
	
	/// Export the brush's graphic
	@IBAction func exportGraphic(sender: AnyObject!) {
		let savePanel = NSSavePanel()
		
		savePanel.prompt = "Export"
		savePanel.allowedFileTypes = [kUTTypeTIFF as String]
		savePanel.beginSheetModalForWindow(windowForSheet!) { (result) in
			if result == NSCancelButton {
				return
			}
			self.brushImage?.TIFFRepresentation?.writeToURL(savePanel.URL!, atomically: true)
		}
	}
	
	/// The following calls `changeName:` before scheduling saving (two events cannot occur in the same loop)
	@IBAction func preSaveDocument(sender: AnyObject!) {
		changeName(sender)
		NSTimer.scheduledTimerWithTimeInterval(0.0, target: self, selector: #selector(BrushDocument.saveDocument(_:)), userInfo: nil, repeats: false)
	}
	
	/// The following calls `changeName:` before scheduling saving (two events cannot occur in the same loop)
	@IBAction func preSaveDocumentAs(sender: AnyObject!) {
		changeName(sender)
		NSTimer.scheduledTimerWithTimeInterval(0.0, target: self, selector: #selector(BrushDocument.saveDocumentAs(_:)), userInfo: nil, repeats: false)
	}
	
	/// Allows the save panel to explore
	override func prepareSavePanel(savePanel: NSSavePanel) -> Bool {
		savePanel.treatsFilePackagesAsDirectories = true
		//[savePanel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications/Seashore.app/Contents/Resources/brushes/"]];
		
		return true;
	}

	override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
		switch menuItem.tag {
		case 120, 121:
			if (pixmap == nil && mask == nil) {
				return false
			}

		default:
			break
		}
		
		return super.validateMenuItem(menuItem)
	}
}
