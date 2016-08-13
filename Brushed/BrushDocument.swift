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

class BrushDocument2: NSDocument, NSWindowDelegate {
	/// A grayscale mask of the brush
	private var mask: UnsafeMutablePointer<UInt8> = nil
	
	/// A coloured pixmap of the brush (RGBA)
	private var pixmap: UnsafeMutablePointer<UInt8> = nil
	
	// All previous bitmaps (for undos)
	private var undoRecords = [BitmapUndo]()
	private var curUndoPos = 0
	
	/// The spacing between brush strokes
	private var spacing: Int32 = 25
	
	/// The width and height of the brush
	private var size: (width: Int32, height: Int32) = (0,0)
	
	// The name of the brush
	private var name = "Untitled";
	
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
		bmpUndo.usePixmap = ObjCBool(usePixmap)
		undoRecords.append(bmpUndo)
	}

	/// Adjust the image of the brush
	func changeImage(newImage: NSBitmapImageRep!) -> Bool {
		return false
	}
	
	/// Adjust the name of the brush
	@IBAction func changeName(sender: AnyObject!) {
		
	}
	
	/// Adjust the brush's spacing
	@IBAction func changeSpacing(sender: AnyObject!) {
		
	}
	
	/// Adjust the brush's type
	@IBAction func changeType(sender: AnyObject!) {
		
	}
	
	/// Loads the given file from disk, returns success
	override func readFromURL(url: NSURL, ofType typeName: String) throws {
		
	}
	
	/// Undoes the image to that which is stored by a given undo record
	func undoImageTo(index: Int) {
		
	}
	
	/// Undoes the name to a given string
	func undoNameTo(string: String) {
		
	}
	
	/// Undoes the spacing to a given value
	func undoSpacingTo(value: Int32) {
		
	}
	
	/// Returns the nib file associated with this class
	override var windowNibName: String? {
		return "BrushDocument"
	}
	//public func windowNibName() -> String!
	
	/// Writes to the given file on disk, returns success
	override func writeToURL(url: NSURL, ofType typeName: String) throws {
		
	}
	
	/// Import a graphic for the brush
	@IBAction func importGraphic(sender: AnyObject!) {
		
	}
	
	/// Export the brush's graphic
	@IBAction func exportGraphic(sender: AnyObject!) {
		
	}
	
	/// The following calls \c changeName: before scheduling saving (two events cannot occur in the same loop)
	@IBAction func preSaveDocument(sender: AnyObject!) {
		
	}
	/// The following calls \c changeName: before scheduling saving (two events cannot occur in the same loop)
	@IBAction func preSaveDocumentAs(sender: AnyObject!) {
		
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
