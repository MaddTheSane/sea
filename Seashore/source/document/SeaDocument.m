#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "SeaDocument.h"
#import "SeaView.h"
#ifdef USE_CENTERING_CLIPVIEW
#import "CenteringClipView.h"
#endif
#import "SeaController.h"
#import "SeaWarning.h"
#import "SeaWhiteboard.h"
#import "UtilitiesManager.h"
#import "TIFFExporter.h"
#import "XCFExporter.h"
#import "PNGExporter.h"
#import "JPEGExporter.h"
#import "GIFExporter.h"
#import "JP2Exporter.h"
#import "SeaPrefs.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import "SeaHelpers.h"
#import "PegasusUtility.h"
#import "SeaPrintView.h"
#import "SeaDocumentController.h"
#import "Units.h"
#import "OptionsUtility.h"
#import "SeaWindowContent.h"
#import "BrushExporter.h"

extern int globalUniqueDocID;
int globalUniqueDocID;

extern IntPoint SeaScreenResolution;

extern BOOL globalReadOnlyWarning;
BOOL globalReadOnlyWarning;

typedef NS_ENUM(int, SeaSpecialStart) {
	kNoStart = 0,
	kNormalStart = 1,
	kOpenStart = 2,
	kPasteboardStart = 3,
	kPlugInStart = 4
};

@implementation SeaDocument
@synthesize contents;
@synthesize measureStyle;
@synthesize whiteboard;
@synthesize operations;
@synthesize current;
@synthesize tools;
@synthesize helpers;
@synthesize warnings;
@synthesize pluginData;
@synthesize textureExporter;
@synthesize brushExporter;
@synthesize uniqueDocID;
@synthesize selection;
@synthesize dataSource;

- (instancetype)init
{
	int dtype, dwidth, dheight, dres;
	BOOL dopaque;
	
	// Initialize superclass first
	if (!(self = [super init]))
		return nil;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	specialStart = kNormalStart;
	
	// Set the measure style
	measureStyle = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] units];
	
	// Create contents
	dtype = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] type];
	dwidth = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] width];
	dheight = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] height];
	dres = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] resolution];
	dopaque = [(SeaDocumentController *)[NSDocumentController sharedDocumentController] opaque];
	contents = [[SeaContent alloc] initWithDocument:self type:dtype width:dwidth height:dheight res:dres opaque:dopaque];
	
	return self;
}

- (instancetype)initWithPasteboard
{
	// Initialize superclass first
	if (!(self = [super init]))
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	specialStart = kPasteboardStart;
	
	// Set the measure style
	measureStyle = [[SeaController seaPrefs] newUnits];
	
	// Create contents
	contents = [[SeaContent alloc] initFromPasteboardWithDocument:self];
	
	// Mark document as dirty
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
	if (self = [super init]) {
		// Reset uniqueLayerID
		uniqueLayerID = -1;
		uniqueFloatingLayerID = 4999;
		
		// Get a unique ID for this document
		uniqueDocID = globalUniqueDocID;
		globalUniqueDocID++;
		
		// Set data members appropriately
		whiteboard = NULL;
		restoreOldType = NO;
		current = YES;
		specialStart = kOpenStart;
		
		// Set the measure style
		measureStyle = [[SeaController seaPrefs] newUnits];
		
		// Do required work
		if ([self readFromURL:url ofType:typeName error:outError]) {
			self.fileURL = url;
			[self setFileType:typeName];
		} else {
			return nil;
		}

	}
	return self;
}

- (instancetype)initWithData:(unsigned char *)data type:(XcfImageType)type width:(int)width height:(int)height
{
	// Initialize superclass first
	if (!(self = [super init]))
		return NULL;
	
	// Reset uniqueLayerID
	uniqueLayerID = -1;
	uniqueFloatingLayerID = 4999;
	
	// Get a unique ID for this document
	uniqueDocID = globalUniqueDocID;
	globalUniqueDocID++;
	
	// Set data members appropriately
	whiteboard = NULL;
	restoreOldType = NO;
	current = YES;
	contents = [[SeaContent alloc] initWithDocument:self data:data type:type width:width height:height res:72];
	specialStart = kPlugInStart;

	// Set the measure style
	measureStyle = [[SeaController seaPrefs] newUnits];

	// Increment change count
	[self updateChangeCount:NSChangeDone];
	
	return self;
}

- (void)awakeFromNib
{
	SeaView *seaView;
#ifdef USE_CENTERING_CLIPVIEW
	id newClipView;
#endif
	
	// Believe it or not sometimes this function is called after it has already run
	if (whiteboard == NULL) {
		exporters = @[gifExporter,
					  jpegExporter,
					  jp2Exporter,
					  pngExporter,
					  tiffExporter,
					  xcfExporter];
		
		// Create a fresh whiteboard and selection manager
		whiteboard = [[SeaWhiteboard alloc] initWithDocument:self];
		selection = [[SeaSelection alloc] initWithDocument:self];
		[whiteboard update];
		
		// Setup the view to display the whiteboard
		seaView = [[SeaView alloc] initWithDocument:self];
#ifdef USE_CENTERING_CLIPVIEW
		newClipView = [[CenteringClipView alloc] initWithFrame:[[view contentView] frame]];
		[view setContentView:newClipView];
#endif
		[view setDocumentView:seaView];
		[view setDrawsBackground:NO];
		
		// set the frame of the window
		[docWindow setFrame:[self standardFrame] display:YES];
		
		// Finally, if the doc has any warnings we are ready for them
		[[SeaController seaWarning] triggerQueue: self];
	}
	
	[docWindow setAcceptsMouseMovedEvents:YES];
}

- (IBAction)saveDocument:(id)sender
{
	current = YES;
	[super saveDocument:sender];
}

- (IBAction)saveDocumentAs:(id)sender
{
	current = YES;
	[super saveDocumentAs:sender];
}

- (SeaView *)docView
{
	return [view documentView];
}

- (NSWindow*)window
{
	return docWindow;
}

- (void)updateWindowColor
{
	[view setBackgroundColor:[[SeaController seaPrefs] windowBack]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError * _Nullable __autoreleasing *)outError
{
	BOOL readOnly = NO;
	
	// Determine which document we have and act appropriately
	if ([XCFContent typeIsEditable: type]) {
		// Load a GIMP or XCF document
		contents = [[XCFContent alloc] initWithDocument:self contentsOfURL:url error:outError];
		if (contents == NULL) {
			return NO;
		}
	} else if ([CocoaContent typeIsEditable: type forDoc: self]) {
		// Load a PNG, TIFF, JPEG document
		// Or a GIF or JP2 document
		contents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:url.path];
		if (contents == NULL) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:
							 @{NSLocalizedDescriptionKey: @"Failed to load editable Cocoa file",
							   NSURLErrorKey: url
							   }];
			}
			return NO;
		}
	} else if ([CocoaContent typeIsViewable: type forDoc: self]) {
		// Load a PDF, PCT, BMP document
		contents = [[CocoaContent alloc] initWithDocument:self contentsOfFile:url.path];
		if (contents == NULL) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:
							 @{NSLocalizedDescriptionKey: @"Failed to load viewable Cocoa file",
							   NSURLErrorKey: url
							   }];
			}
			return NO;
		}
		readOnly = YES;
	} else if ([XBMContent typeIsEditable: type]) {
		// Load a X bitmap document
		contents = [[XBMContent alloc] initWithDocument:self contentsOfFile:url.path];
		if (contents == NULL) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:
							 @{NSLocalizedDescriptionKey: @"Failed to load X11 bitmap",
							   NSURLErrorKey: url
							   }];
			}
			return NO;
		}
		readOnly = YES;
	} else if ([SVGContent typeIsViewable: type]) {
		// Load a SVG document
		contents = [[SVGContent alloc] initWithDocument:self contentsOfFile:url.path];
		if (contents == NULL) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:
							 @{NSLocalizedDescriptionKey: @"Failed to load SVG",
							   NSURLErrorKey: url
							   }];
			}
			return NO;
		}
		readOnly = YES;
	} else {
		// Handle an unknown document type
		NSLog(@"Unknown type passed to readFromURL:<%@>ofType:<%@>error:", url.path, type);
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:
						 @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unknown type %@", type],
						   NSURLErrorKey: url
						   }];
		}
		return NO;
	}
	
	if (readOnly && !globalReadOnlyWarning) {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"read only message", @"This file is in a read-only format, as such you cannot save this file. This warning will not be displayed for subsequent files in a read-only format.") forDocument: self level:SeaWarningImportanceLow];
		globalReadOnlyWarning = YES;
	}

	
	return YES;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
	BOOL result = NO;
	
	for (id<AbstractExporter> exporter in exporters) {
		if ([[SeaDocumentController sharedDocumentController]
			 type: typeName
			 isContainedInDocType:[exporter title]
			 ]) {
			[exporter writeDocument:self toFile:[url path]];
			result = YES;
			break;
		}
	}
	
	if (!result) {
		NSLog(@"Unknown type passed to writeToURL:<%@>ofType:<%@>error:", url, typeName);
		if (outError) {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:
						 @{NSLocalizedFailureReasonErrorKey:  [NSString stringWithFormat:@"Unknown type passed to writeToURL:<%@>ofType:<%@>error:", url, typeName],
						   NSURLErrorKey: url
						   }];
		}
	}
	return result;
}

- (void)printShowingPrintPanel:(BOOL)showPanels
{
	SeaPrintView *printView;
	NSPrintOperation *op;
    
	// Create a print operation for the given view
	printView = [[SeaPrintView alloc] initWithDocument:self];
	op = [NSPrintOperation printOperationWithView:printView printInfo:[self printInfo]];
	
	// Insist the view be scaled to fit
	[op setShowsPrintPanel:showPanels];
    [self runModalPrintOperation:op delegate:NULL didRunSelector:NULL contextInfo:NULL];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	NSInteger exporterIndex = -1;
	
	// Implement the view that allows us to select layers
	[savePanel setAccessoryView:accessoryView];
	
	// Find the default exporter's index
	for (id<AbstractExporter> exporter in exporters) {
		if ([[SeaDocumentController sharedDocumentController]
			 type: [self fileType]
			 isContainedInDocType:[exporter title]
			 ]) {
			exporterIndex = [exporters indexOfObject:exporter];
			break;
		}
	}
	
	// Deal with the rare case where we don't find one
	if (exporterIndex == -1) {
		exporterIndex = [exporters count] - 1;
		[self setFileType:[exporters[[exporters count] - 1] title]];
	}
	
	// Add in our exporters
	[exportersPopUp removeAllItems];
	for (id<AbstractExporter> exporter in exporters) {
		[exportersPopUp addItemWithTitle:[exporter title]];
	}
	[exportersPopUp selectItemAtIndex:exporterIndex];
	savePanel.allowedFileTypes = @[exporters[exporterIndex].fileType];
	
	// Finally set the options button state appropriately
	[optionsButton setEnabled:[exporters[[exportersPopUp indexOfSelectedItem]] hasOptions]];
	[optionsSummary setStringValue:[exporters[[exportersPopUp indexOfSelectedItem]] optionsString]];
	
	return YES;
}

- (IBAction)showExporterOptions:(id)sender
{
	[exporters[[exportersPopUp indexOfSelectedItem]] showOptions:self];
	[optionsSummary setStringValue:[exporters[[exportersPopUp indexOfSelectedItem]] optionsString]];
}

- (IBAction)exporterChanged:(id)sender
{
	((NSSavePanel*)[exportersPopUp window]).allowedFileTypes = @[[exporters[[exportersPopUp indexOfSelectedItem]] fileType]];
	[self setFileType:[exporters[[exportersPopUp indexOfSelectedItem]] title]];
	[optionsButton setEnabled:[exporters[[exportersPopUp indexOfSelectedItem]] hasOptions]];
	[optionsSummary setStringValue:[exporters[[exportersPopUp indexOfSelectedItem]] optionsString]];
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
}

- (void)windowDidEndSheet:(NSNotification *)notification
{
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	NSPoint point;
	
	[[SeaController utilitiesManager] activate:self];
	if ([docWindow attachedSheet])
		[[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = [docWindow mouseLocationOutsideOfEventStream];
	[[self docView] updateRulerMarkings:point andStationary:NSMakePoint(-256e6, -256e6)];
	[(OptionsUtility *)[(UtilitiesManager *)[SeaController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	NSPoint point;
	
	[helpers endLineDrawing];
	if ([docWindow attachedSheet])
		[[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:NO];
	else
		[[[SeaController utilitiesManager] pegasusUtilityFor:self] setEnabled:YES];
	point = NSMakePoint(-256e6, -256e6);
	[[self docView] updateRulerMarkings:point andStationary:point];
	[[[SeaController utilitiesManager] optionsUtilityFor:self] viewNeedsDisplay];
	[gColorPanel orderOut:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[[self docView] clearScrollingMode];
}

- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	// I don't know what would call this besides the doc window
	if(sender != docWindow){
		NSLog(@"An unknown window (%@) has attempted to zoom.", sender);
		return NSZeroRect;
	}
	return [self standardFrame];
}

- (NSRect)standardFrame
{
	NSRect frame;
	float xScale, yScale;
	NSRect rect;
	
	// Get the old frame so we can preserve the top-left origin
	frame = [docWindow frame];
	float minHeight = 480;

	// Store the initial conditions of the window 
	rect.origin.x = frame.origin.x;
	rect.origin.y = frame.origin.y;
	xScale = [contents xscale];
	yScale = [contents yscale];
	rect.size.width = [(SeaContent *)contents width]  * xScale;
	rect.size.height = [(SeaContent *)contents height] * yScale;
		
	 // Remember the rulers have dimension
	 if([[SeaController seaPrefs] rulers]){
		 rect.size.width += 22;
		 rect.size.height += 31;
	 }
	// Titlebar
	rect.size.height += 22;
	minHeight += 22;
	// Toolbar
	if([[docWindow toolbar] isVisible]){
		// This is innacurate because the toolbar can actually change in height,
		// depending on settings (labels, small etc...)
		rect.size.height += 35;
		minHeight += 35;
	}
	// Options Bar
	rect.size.height += [[docWindow contentView] sizeForRegion: SeaWindowRegionOptionsBar];
	 // Status Bar
	rect.size.height += [[docWindow contentView] sizeForRegion: SeaWindowRegionStatusBar];
	
	 // Layers
	rect.size.width += [[docWindow contentView] sizeForRegion: SeaWindowRegionSidebar];
	
	// Disallow ridiculously small or large windows
	NSRect defaultFrame = [[docWindow screen] frame];
	if (rect.size.width > defaultFrame.size.width) rect.size.width = defaultFrame.size.width;
	if (rect.size.height > defaultFrame.size.height) rect.size.height = defaultFrame.size.height;
	if (rect.size.width < 724) rect.size.width = 724;
	if (rect.size.height < minHeight) rect.size.height = minHeight;
	
	// Reset the origin's y-value to keep the titlebar level
	rect.origin.y = rect.origin.y - rect.size.height + frame.size.height;
	
	return rect;
}

- (void)close
{
	[[SeaController utilitiesManager] shutdownFor:self];

	// Then call our supervisor
	[super close];
}

- (NSInteger)uniqueLayerID
{
	uniqueLayerID++;
	return uniqueLayerID;
}

- (NSInteger)uniqueFloatingLayerID
{
	uniqueFloatingLayerID++;
	return uniqueFloatingLayerID;
}

- (NSString *)windowNibName
{
    return @"SeaDocument";
}

- (IBAction)customUndo:(id)sender
{
	[[self undoManager] undo];
}

- (IBAction)customRedo:(id)sender
{
	[[self undoManager] redo];
}

- (BOOL)locked
{
	return locked || ([docWindow attachedSheet] != NULL);
}

- (void)lock
{
	locked = YES;
}

- (void)unlock
{
	locked = NO;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	NSString *type = [self fileType];
	
	[helpers endLineDrawing];
	if ([menuItem tag] == 171) {
		if ([type isEqualToString:@"PDF Document"] || [type isEqualToString:@"PICT Document"] || [type isEqualToString:@"Graphics Interchange Format Image"] || [type isEqualToString:@"Windows Bitmap Image"])
			return NO;
		//if ([self isDocumentEdited] == NO)
		//	return NO;
	}
	
	if ([menuItem tag] == 180)
		return ![self locked] && [[self undoManager] canUndo];
	if ([menuItem tag] == 181)
		return ![self locked] && [[self undoManager] canRedo];

	return YES;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	// Remember the old type
	oldType = [self fileType];
	if (saveOperation == NSSaveToOperation) {
		restoreOldType = YES;
	}
	
	// Check we're not meant to call someone
	if (delegate)
		NSLog(@"Delegate specified for save panel");
	
	// Run the super's method calling our custom
	[super runModalSavePanelForSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
	
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
	// Restore the old type
	if (restoreOldType && didSave) {
		[self setFileType:oldType];
		oldType = nil;
		restoreOldType = NO;
	}
	else if (!didSave) {
		[self setFileType:oldType];
		oldType = nil;
		restoreOldType = NO;
	}
}

- (NSString *)fileTypeFromLastRunSavePanel
{
	return [self fileType];
}


- (NSScrollView *)scrollView
{
	return (NSScrollView *)view;
}

@end
