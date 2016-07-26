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
	
	@objc(addToDocument:contentsOfURL:error:) func add(to doc: SeaDocument, contentsOf path: NSURL) throws {
		trueSize = getDocumentSize(path.fileSystemRepresentation)
		size = trueSize
		let fm = NSFileManager.defaultManager()

		/*
	id imageRep;
	SeaLayer *layer;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSImage *image;
	NSString *importerPath;
	NSString *path_in, *path_out, *width_arg, *height_arg;
	NSArray *args;
	NSTask *task;
		
	// Load nib file
	[NSBundle loadNibNamed:@"SVGContent" owner:self];
	
	// Run the scaling panel
	[scalePanel center];
	trueSize = getDocumentSize([path fileSystemRepresentation]);
	size.width = trueSize.width; size.height = trueSize.height;
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
	[scaleSlider setIntValue:2];
	[NSApp runModalForWindow:scalePanel];
	[scalePanel orderOut:self];
	
	// Add all plug-ins to the array
	importerPath = [[gMainBundle builtInPlugInsPath] stringByAppendingPathComponent:@"SVGImporter.app/Contents/MacOS/SVGImporter"];
	if ([fm fileExistsAtPath:importerPath]) {
		if (![fm fileExistsAtPath:@"/tmp/seaimport"]) [fm createDirectoryAtPath:@"/tmp/seaimport" withIntermediateDirectories:YES attributes:nil error:NULL];
		path_in = path;
		path_out = [NSString stringWithFormat:@"/tmp/seaimport/%@.png", [[path lastPathComponent] stringByDeletingPathExtension]];
		if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
			width_arg = [NSString stringWithFormat:@"%d", size.width];
			height_arg = [NSString stringWithFormat:@"%d", size.height];
			args = @[path_in, path_out, width_arg, height_arg];
		}
		else {
			args = @[path_in, path_out];
		}
		[waitPanel center];
		[waitPanel makeKeyAndOrderFront:self];
		task = [NSTask launchedTaskWithLaunchPath:importerPath arguments:args];
		[spinner startAnimation:self];
		while ([task isRunning]) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
		[spinner stopAnimation:self];
		[waitPanel orderOut:self];
	}
	else {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"SVG message", @"Seashore is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on Seashore's website.") level:kHighImportance];
		return NO;
	}
	
	// Open the image
	image = [[NSImage alloc] initByReferencingFile:path_out];
	if (image == NULL) {
		return NO;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [image representations][0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		}
	}
	if (imageRep == NULL) {
		return NO;
	}
		
	// Create the layer
	layer = [[CocoaLayer alloc] initWithImageRep:imageRep document:doc spp:[[doc contents] spp]];
	if (layer == NULL) {
		return NO;
	}
	
	// Rename the layer
	[layer setName:[[NSString alloc] initWithString:[[path lastPathComponent] stringByDeletingPathExtension]]];
	
	// Add the layer
	[[doc contents] addLayerObject:layer];
	
	// Now forget the NSImage
	
	// Position the new layer correctly
	[[[doc operations] seaAlignment] centerLayerHorizontally:NULL];
	[[[doc operations] seaAlignment] centerLayerVertically:NULL];
	
	return YES;

		*/
	}
	
	/// Closes the current modal dialog.
	@IBAction func endPanel(sender: AnyObject!) {
		
	}
	
	/// Updates the document's expected size.
	@IBAction func update(sender: AnyObject!) {
		
	}

}
