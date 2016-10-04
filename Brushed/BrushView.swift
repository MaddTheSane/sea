//
//  BrushView.swift
//  Brushed
//
//  Created by C.W. Betts on 10/4/16.
//
//
/*
	Brushed 0.8.1
	
	This class provides a visual representation of the brush.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

import Cocoa

class BrushView: NSView {
	/// The document associated with this view
	@IBOutlet weak var document: BrushDocument!
	
	override func draw(_ dirtyRect: NSRect) {
		// Fill in background
		NSColor.white.setFill()
		NSColor.black.setStroke()
		let aPath = NSBezierPath(rect: bounds)
		aPath.fill()
		aPath.stroke()

		// Center and draw the image of the brush
		if let brushImage = document.brushImage {
			if ((brushImage.size.width > bounds.size.width - 20.0) && (brushImage.size.height * (bounds.size.width - 20.0) / brushImage.size.width <= bounds.size.height)) {
				brushImage.size = NSSize(width: bounds.size.width - 20.0, height: brushImage.size.height * (bounds.size.width - 20.0) / brushImage.size.width)
			} else if ((brushImage.size.height > bounds.size.height - 20.0) && (brushImage.size.width * (bounds.size.height - 20.0) / brushImage.size.height <= bounds.size.width)) {
				brushImage.size = NSMakeSize(brushImage.size.width * (bounds.size.height - 20.0) / brushImage.size.height, bounds.size.height - 20.0)
			}
			var whereLoc = NSPoint()
			whereLoc.x = bounds.size.width / 2 - brushImage.size.width / 2;
			whereLoc.y = bounds.size.height / 2 - brushImage.size.height / 2;
			brushImage.draw(at: whereLoc, from: .zero, operation: .sourceOver, fraction: 1)
		}
	}
}
