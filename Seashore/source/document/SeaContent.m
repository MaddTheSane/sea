#import "SeaContent.h"
#import "SeaLayer.h"
#if MAIN_COMPILE
#import "SeaDocument.h"
#import "UtilitiesManager.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "PegasusUtility.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "CenteringClipView.h"
#import "Bitmap.h"
#import "SeaWarning.h"
#import "XCFContent.h"
#import "CocoaContent.h"
#import "XBMContent.h"
#import "SVGContent.h"
#import "CocoaImporter.h"
#import "XCFImporter.h"
#import "XBMImporter.h"
#import "SVGImporter.h"
#import "ToolboxUtility.h"
#import "CloneTool.h"
#import "PositionTool.h"
#import "SeaTools.h"
#import "SeaCompositor.h"
#import "StatusUtility.h"
#import "SeaDocumentController.h"
#import "SeaDocument.h"
#import "CenteringClipView.h"
#import "IndiciesKeeper.h"

extern IntPoint gScreenResolution;
static NSString*	FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSString*	DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";
#endif

@implementation SeaContent {
#if MAIN_COMPILE
	// The keeper we use to keep IndiciesRecords in memory
	IndiciesKeeper keeper;
#else
	IntPoint gScreenResolution;
#endif
}
@synthesize selectedChannel;
@synthesize cmykSave;
@synthesize trueView;
@synthesize activeLayerIndex;

#if MAIN_COMPILE
- (instancetype)initWithDocument:(id)doc
{
	if (self = [super init]) {
	// Set the data members to reasonable values
	xres = yres = 72;
	height = width = type = 0;
	lostprops = NULL; lostprops_len = 0;
	parasites = NULL; parasites_count = 0;
	exifData = NULL;
	layers = NULL; activeLayerIndex = 0;
	layersToUndo = [[NSMutableArray alloc] init];
	layersToRedo = [[NSMutableArray alloc] init];
	orderings = [[NSMutableArray alloc] init];
	deletedLayers = [[NSArray alloc] init];
	selectedChannel = kAllChannels; trueView = NO;
	cmykSave = NO;
	keeper = allocKeeper();
	document = doc;
	}
	
	return self;
}

- (instancetype)initFromPasteboardWithDocument:(id)doc
{
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSData *imageRepData;
	NSBitmapImageRep *imageRep;
	NSInteger sspp, dspp;
	NSData *profile;
	ColorSyncProfileRef cmProfileLoc = NULL;
	NSInteger bipp, bypr, bps;
	unsigned char *data;
	BMPColorSpace space = -1;
	
	// Get the data from the pasteboard
	NSString *imageRepDataType = [pboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
	//if (imageRepDataType == NULL) {
	//	imageRepDataType = [pboard availableTypeFromArray:@[NSPICTPboardType]];
	//	imageRepData = [pboard dataForType:imageRepDataType];
	//	image = [[NSImage alloc] initWithData:imageRepData];
	//	imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	//}
	//else {
		imageRepData = [pboard dataForType:imageRepDataType];
		imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
	//}
	if ((self = [self initWithDocument:doc]) == nil) {
		return nil;
	}
	
	// Fill out as many of the properties as possible
	height = (int)[imageRep pixelsHigh];
	width = (int)[imageRep pixelsWide];

	// Determine the color space of the pasteboard image and the type
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace]) {
		space = kGrayColorSpace;
		type = XCF_GRAY_IMAGE;
	}
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace]) {
		space = kInvertedGrayColorSpace;
		type = XCF_GRAY_IMAGE;
	}
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
		space = kRGBColorSpace;
		type = XCF_RGB_IMAGE;
	}
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace]) {
		space = kCMYKColorSpace;
		type = XCF_RGB_IMAGE;
	}
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		return NULL;
	}
	
	// Extract color profile
	profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
	if (profile) {
		cmProfileLoc = ColorSyncProfileCreate((__bridge CFDataRef)(profile), NULL);
	}
	
	// Put it in a nice form
	sspp = [imageRep samplesPerPixel];
	bps = [imageRep bitsPerSample];
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
	if (type == XCF_RGB_IMAGE)
		dspp = 4;
	else
		dspp = 2;
	data = convertBitmapColorSync(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], width, height, sspp, bipp, bypr, space, cmProfileLoc, bps, 0);
	if (cmProfileLoc) {
		CFRelease(cmProfileLoc);
	}
	
	if (!data) {
		NSLog(@"Required conversion not supported.");
		return NULL;
	}
	unpremultiplyBitmap(dspp, data, data, width * height);
	
	// Add layer
	layers = @[[[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, width, height) data:data spp:(int)dspp]];
	activeLayerIndex = 0;
	
	return self;
}

- (instancetype)initWithDocument:(id)doc type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres opaque:(BOOL)dopaque
{	
	// Call the core initializer
	if (![self initWithDocument:doc])
		return NULL;
	
	// Set the data members to appropriate values
	xres = yres = dres;
	type = dtype;
	height = dheight; width = dwidth;
	
	// Add in a single layer
	layers = @[[[SeaLayer alloc] initWithDocument:doc width:dwidth height:dheight opaque:dopaque spp:[self spp]]];
	
	return self;
}

- (instancetype)initWithDocument:(id)doc data:(unsigned char *)ddata type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres
{
	// Call the core initializer
	if (![self initWithDocument:doc])
		return NULL;
	
	// Set the data members to appropriate values
	xres = yres = dres;
	type = dtype;
	height = dheight; width = dwidth;
	
	// Add in a single layer
	layers = @[[[SeaLayer alloc] initWithDocument:doc rect:IntMakeRect(0, 0, dwidth, dheight) data:ddata spp:(dtype == XCF_RGB_IMAGE) ? 4 : 2]];
	
	return self;
}

#else

- (instancetype)init
{
	if (self = [super init]) {
		// Set the data members to reasonable values
		xres = yres = 72;
		height = width = type = 0;
		lostprops = NULL; lostprops_len = 0;
		parasites = NULL; parasites_count = 0;
		exifData = NULL;
		layers = NULL; activeLayerIndex = 0;
		layersToUndo = [NSMutableArray array];
		layersToRedo = [NSMutableArray array];
		orderings = [NSMutableArray array];
		deletedLayers = [[NSArray alloc] init];
		selectedChannel = kAllChannels; trueView = NO;
		cmykSave = NO;
		gScreenResolution = IntMakePoint(1024, 768);
	}
	
	return self;
}
#endif

- (void)dealloc
{
#if MAIN_COMPILE
	freeKeeper(&keeper);
#endif
	if (parasites) {
		for (int i = 0; i < parasites_count; i++) {
			CFRelease(parasites[i].name);
			free(parasites[i].data);
		}
		free(parasites);
	}
	if (lostprops)
		free(lostprops);
}

#if MAIN_COMPILE
- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
	id layer;
	int i;
	
	// Change the width and height of the document
	width += left + right;
	height += top + bottom;
	
	// Change the layer offsets of the document
	for (i = 0; i < [layers count]; i++) {
		layer = layers[i];
		if (left) [layer setOffsets:IntMakePoint([layer xoff] + left, [layer yoff])];
		if (top) [layer setOffsets:IntMakePoint([layer xoff], [layer yoff] + top)];
	}
	[[document selection] adjustOffset:IntMakePoint(left, top)];
}
#endif

- (int)type
{
	return type;
}

- (int)spp
{
	int result = 0;
	
	switch (type) {
		case XCF_RGB_IMAGE:
			result = 4;
		break;
		case XCF_GRAY_IMAGE:
			result = 2;
		break;
		default:
			NSLog(@"Document type not recognised by spp");
		break;
	}
	
	return result;
}

- (int)xres
{
	return xres;
}

- (int)yres
{
	return yres;
}

- (float)xscale
{
	float xscale =
#if MAIN_COMPILE
	[[document docView] zoom];
#else
	1.0;
#endif
	
	if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
		xscale /= ((float)xres / (float)gScreenResolution.x);
	
	return xscale;
}

- (float)yscale
{
	float yscale =
#if MAIN_COMPILE
[[document docView] zoom];
#else
	1;
#endif
	if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
		yscale /= ((float)yres / (float)gScreenResolution.y);
	
	return yscale;
}

#if MAIN_COMPILE
- (void)setResolution:(IntResolution)newRes
{
	xres = newRes.x;
	yres = newRes.y;
}
#endif

- (int)height
{
	return height;
}

- (int)width
{
	return width;
}

#if MAIN_COMPILE
- (void)setWidth:(int)newWidth height:(int)newHeight
{
	width = newWidth;
	height = newHeight;
}
#endif

- (char *)lostprops
{
	return lostprops;
}

- (int)lostprops_len
{
	return lostprops_len;
}

- (ParasiteData *)parasites
{
	return parasites;
}

- (int)parasites_count
{
	return parasites_count;
}

- (ParasiteData *)parasiteWithName:(NSString *)name
{
	int i;
	
	for (i = 0; i < parasites_count; i++) {
		if ([name isEqualToString:(__bridge NSString *)(parasites[i].name)])
			return &(parasites[i]);
	}
	
	return NULL;
}

- (void)deleteParasiteWithName:(NSString *)name
{
	int i, x;
	
	// Find the parasite to delete
	x = -1;
	for (i = 0; i < parasites_count && x == -1; i++) {
		if ([name isEqualToString:(__bridge NSString*)parasites[i].name])
			x = i;
	}
	
	if (x != -1) {
		
		// Destroy it
		CFRelease(parasites[x].name);
		free(parasites[x].data);
	
		// Update the parasites list
		parasites_count--;
		if (parasites_count > 0) {
			for (i = x; i < parasites_count; i++) {
				parasites[i] = parasites[i + 1];
			}
			parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
		}
		else {
			free(parasites);
			parasites = NULL;
		}
	
	}
}

- (void)addParasite:(ParasiteData)parasite
{
	// Delete existing parasite with the same name (if any)
	[self deleteParasiteWithName:(__bridge NSString*)parasite.name];
	
	// Add parasite
	parasites_count++;
	if (parasites_count == 1) parasites = malloc(sizeof(ParasiteData) * parasites_count);
	else parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
	parasites[parasites_count - 1] = parasite;
}

#if MAIN_COMPILE
- (NSColor *)foreground
{
	id foreground;
	
	foreground = [[[SeaController utilitiesManager] toolboxUtilityFor:document] foreground];
	if (type == XCF_RGB_IMAGE && selectedChannel != kAlphaChannel)
		return [foreground colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	else if (type == XCF_GRAY_IMAGE)
		return [foreground colorUsingColorSpaceName:NSDeviceWhiteColorSpace];
	else
		return [[foreground colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

- (NSColor *)background
{
	id background;
	
	background = [[[SeaController utilitiesManager] toolboxUtilityFor:document] background];
	if (type == XCF_RGB_IMAGE && selectedChannel != kAlphaChannel)
		return [background colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	else if (type == XCF_GRAY_IMAGE)
		return [background colorUsingColorSpaceName:NSDeviceWhiteColorSpace];
	else
		return [[background colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}
#endif

- (void)setCMYKSave:(BOOL)value
{
	cmykSave = value;
}

- (BOOL)cmykSave
{
	return cmykSave;
}

- (NSDictionary *)exifData
{
	return exifData;
}

- (id)layer:(NSInteger)index
{
	return layers[index];
}

- (NSInteger)layerCount
{
	return [layers count];
}

- (SeaLayer*)activeLayer
{
	return (activeLayerIndex < 0) ? NULL : layers[activeLayerIndex];
}

#if MAIN_COMPILE
- (void)layerBelow
{
	NSInteger newIndex;
	[[document helpers] activeLayerWillChange];
	if(activeLayerIndex + 1 >= [self layerCount])
	{
		newIndex = 0;
	}else {
		newIndex = activeLayerIndex + 1;
	}
	[self setActiveLayerIndex: newIndex];
	[[document helpers] activeLayerChanged:kLayerSwitched rect:NULL];	
}

- (void)layerAbove
{
	NSInteger newIndex;
	[[document helpers] activeLayerWillChange];
	if(activeLayerIndex - 1 < 0)
	{
		newIndex = [self layerCount] - 1;
	}else {
		newIndex = activeLayerIndex - 1;
	}
	[self setActiveLayerIndex: newIndex];
	[[document helpers] activeLayerChanged:kLayerSwitched rect:NULL];	
}

- (BOOL)canImportLayerFromFile:(NSString *)path
{
	NSString *docType;
	BOOL success = NO;
	
	// Determine which document we have and act appropriately	
	docType = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
																(__bridge CFStringRef)[path pathExtension],
																(CFStringRef)@"public.data"));
	
	success = [XCFContent typeIsEditable:docType] ||
		[XBMContent typeIsEditable:docType] ||
		[CocoaContent typeIsViewable:docType forDoc: document] ||
		[SVGContent typeIsViewable:docType];
	
	return success;
}

- (BOOL)importLayerFromFile:(NSString *)path
{
	NSString *docType;
	BOOL success = NO;
	id importer;
	
	docType = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
																(__bridge CFStringRef)[path pathExtension],
																(CFStringRef)@"public.data"));

	if ([XCFContent typeIsEditable:docType]) {
		
		// Load GIMP or XCF layers
		importer = [[XCFImporter alloc] init];
		success = [importer addToDocument:document contentsOfFile:path];
		
	} else if ([CocoaContent typeIsViewable:docType forDoc: document]) {
		
		// Load PNG, TIFF, JPEG, GIF and other layers
		importer = [[CocoaImporter alloc] init];
		success = [importer addToDocument:document contentsOfFile:path];
	
	
	} else if ([XBMContent typeIsEditable:docType]) {
		// Load X bitmap layers
		importer = [[XBMImporter alloc] init];
		success = [importer addToDocument:document contentsOfFile:path];
	} else if ([SVGContent typeIsViewable:docType]) {
		// Load SVG layers
		importer = [[SVGImporter alloc] init];
		success = [importer addToDocument:document contentsOfFile:path];
	} else {
		// Handle an unknown document type
		NSLog(@"Unknown type passed to importLayerFromFile:<%@> docType:<%@>", path, docType);
		success = NO;
	
	}

	// Inform the user of failure
	if (!success){
		[[SeaController seaWarning] addMessage:LOCALSTR(@"import failure message", @"The selected file was not able to be successfully imported into this document.") forDocument:document level:kHighImportance];
	}
		
	return success;
}

- (void)importLayer
{
	// Run import dialog
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	NSArray *types = [(SeaDocumentController*)[NSDocumentController sharedDocumentController] readableTypes];
	openPanel.allowedFileTypes = types;
	[openPanel beginSheetModalForWindow:[document window] completionHandler:^(NSInteger result) {
		NSArray<NSURL*> *filenames = [openPanel URLs];
		
		if (result == NSOKButton) {
			for (NSURL *aURL in filenames) {
				[self importLayerFromFile:[aURL path]];
			}
		}

	}];
}

- (void)addLayer:(NSInteger)index
{
	NSArray *tempArray = @[];
	int i;
	
	if([[document selection] floating]){
		unsigned char *data;
		int spp = [self spp];
		IntRect dataRect;
		id layer;
		// Save the existing selection
		layer = layers[activeLayerIndex];
		dataRect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);;
		data = malloc(make_128(dataRect.size.width * dataRect.size.height * spp));
		memcpy(data, [(SeaLayer *)layer data], dataRect.size.width * dataRect.size.height * spp);
		
		// Delete the floating layer
		[self deleteLayer:activeLayerIndex];
		
		// Clear the selection
		[[document selection] clearSelection];

		// Inform the helpers we will change the layer
		[[document helpers] activeLayerWillChange];
		
		// Create a new array with all the existing layers and the one being added
		layer = [[SeaLayer alloc] initWithDocument:document rect:dataRect data:data spp:spp];
		for (i = 0; i < [layers count] + 1; i++) {
			if (i == activeLayerIndex)
				tempArray = [tempArray arrayByAddingObject:layer];
			else
				tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? layers[i - 1] : layers[i]];
		}
		
		// Now substitute in our new array
		layers = tempArray;
		
		// Inform document of layer change
		[[document helpers] activeLayerChanged:kLayerAdded rect:&dataRect];
		
		// Make action undoable
		[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];	
	}else{
	
		// Inform the helpers we will change the layer
		[[document helpers] activeLayerWillChange];
		
		// Correct index
		if (index == kActiveLayer) index = activeLayerIndex;
		
		// Create a new array with all the existing layers and the one being added
		for (i = 0; i < [layers count] + 1; i++) {
			if (i == index)
				tempArray = [tempArray arrayByAddingObject:[[SeaLayer alloc] initWithDocument:document width:width height:height opaque:NO spp:[self spp]]];
			else
				tempArray = [tempArray arrayByAddingObject:(i > index) ? layers[i - 1] : layers[i]];
		}
		
		// Now substitute in our new array
		layers = tempArray;
		
		// Inform document of layer change
		[[document helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
		
		// Make action undoable
		[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
	}
}

- (void)addLayerObject:(id)layer
{
	NSArray *tempArray = @[];
	NSInteger i, index;
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Find index
	index = activeLayerIndex;
	
	// Create a new array with all the existing layers and the one being added
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == index)
			tempArray = [tempArray arrayByAddingObject:layer];
		else
			tempArray = [tempArray arrayByAddingObject:(i > index) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Inform document of layer change
	[[document helpers] activeLayerChanged:kTransparentLayerAdded rect:NULL];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)addLayerFromPasteboard:(id)pboard
{
	NSArray *tempArray = @[];
	NSData *imageRepData;
	NSBitmapImageRep *imageRep;
	IntRect rect;
	id layer;
	unsigned char *data, *tdata;
	NSInteger i, spp = [[document contents] spp], sspp, dspp;
	ColorSyncProfileRef cmProfileLoc = NULL;
	NSInteger bipp, bypr, bps;
	NSPoint centerPoint;
	
	// Get the data from the pasteboard
	NSString *imageRepDataType = [pboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
	//if (imageRepDataType == NULL) {
	//	imageRepDataType = [pboard availableTypeFromArray:@[NSPICTPboardType]];
	//	imageRepData = [pboard dataForType:imageRepDataType];
	//	image = [[NSImage alloc] initWithData:imageRepData];
	//	imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	//}
	//else {
		imageRepData = [pboard dataForType:imageRepDataType];
		imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
	//}
	
	// Determine the color space of pasteboard image
	BMPColorSpace space = -1;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
		space = kGrayColorSpace;
	//if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
	//	space = kInvertedGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
		space = kRGBColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
		space = kCMYKColorSpace;
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		return;
	}
	
	// Extract color profile
	NSData *profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
	if (profile) {
		cmProfileLoc = ColorSyncProfileCreate((__bridge CFDataRef)(profile), NULL);
	}
	
	// Work out the correct center point
	if (height > 64 && width > 64 && [imageRep pixelsHigh] > height - 12 && [imageRep pixelsWide] > width - 12) { 
		rect = IntMakeRect((int)(width / 2 - [imageRep pixelsWide] / 2), (int)(height / 2 - [imageRep pixelsHigh] / 2), (int)[imageRep pixelsWide], (int)[imageRep pixelsHigh]);
	}
	else {
		centerPoint = [(CenteringClipView *)[[document docView] superview] centerPoint];
		centerPoint.x /= [[document docView] zoom];
		centerPoint.y /= [[document docView] zoom];
		rect = IntMakeRect((int)(centerPoint.x - [imageRep pixelsWide] / 2), (int)(centerPoint.y - [imageRep pixelsHigh] / 2), (int)[imageRep pixelsWide], (int)[imageRep pixelsHigh]);
	}
	
	// Put it in a nice form
	sspp = [imageRep samplesPerPixel];
	bps = [imageRep bitsPerSample];
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
	dspp = spp;
	if (spp == 4 && selectedChannel == kAlphaChannel) {
		dspp = 2;
	}
	data = convertBitmapColorSync(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], rect.size.width, rect.size.height, sspp, bipp, bypr, space, cmProfileLoc, bps, 0);
	if (cmProfileLoc) {
		CFRelease(cmProfileLoc);
	}
	if (!data) {
		NSLog(@"Required conversion not supported.");
		return;
	}
	unpremultiplyBitmap(dspp, data, data, rect.size.width * rect.size.height);
	
	// Handle the special case where a GGGA graphic is wanted
	if (spp == 4 && dspp == 2) {
		tdata = malloc(make_128(rect.size.width * rect.size.height * 4));
		for (i = 0; i < rect.size.width * rect.size.height; i++) {
			tdata[i * 4] = data[i * 2];
			tdata[i * 4 + 1] = data[i * 2];
			tdata[i * 4 + 2] = data[i * 2];
			tdata[i * 4 + 3] = data[i * 2 + 1];
		}
		free(data);
		data = tdata;
	}
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Create a new array with all the existing layers and the one being added
	layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data spp:(int)spp];
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == activeLayerIndex)
			tempArray = [tempArray arrayByAddingObject:layer];
		else
			tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Inform document of layer change
	[[document helpers] activeLayerChanged:kLayerAdded rect:&rect];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];	
}

- (void)copyLayer:(id)layer
{
	NSArray *tempArray = @[];
	NSInteger i, index;
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Create a new array with all the existing layers and the one being added
	index = activeLayerIndex;
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == index)
			tempArray = [tempArray arrayByAddingObject:[[SeaLayer alloc] initWithDocument:document layer:layer]];
		else
			tempArray = [tempArray arrayByAddingObject:(i > index) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Inform document of layer change
	[[document helpers] activeLayerChanged:kLayerAdded rect:NULL];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)duplicateLayer:(NSInteger)index
{
	NSArray *tempArray = @[];
	IntRect rect;
	NSInteger i;
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	
	// Create a new array with all the existing layers and the one being added
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == index)
			tempArray = [tempArray arrayByAddingObject:[[SeaLayer alloc] initWithDocument:document layer:layers[index]]];
		else
			tempArray = [tempArray arrayByAddingObject:(i > index) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Inform document of layer change
	rect = IntMakeRect([layers[index] xoff], [layers[index] yoff], [(SeaLayer *)layers[index] width], [(SeaLayer *)layers[index] height]);
	[[document helpers] activeLayerChanged:kLayerAdded rect:&rect];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
}

- (void)deleteLayer:(NSInteger)index
{
	id layer;
	NSArray *tempArray = @[];
	IntRect rect;
	int i;
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	layer = layers[index];
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Clear the selection if the layer is a floating one
	if ([layer floating]){
		[[document selection] clearSelection];
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] anchorTool];
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:YES];
	}
		
	// Create a new array with all the existing layers except the one being deleted
	for (i = 0; i < [layers count]; i++) {
		if (i != index) {
			tempArray = [tempArray arrayByAddingObject:layers[i]];
		}
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Add the layer to the lost layers (compressed)
	[layer compress];
	deletedLayers = [deletedLayers arrayByAddingObject:layer];
	
	// Change the layer
	if (activeLayerIndex >= [layers count]) activeLayerIndex = [layers count] - 1;
	
	// Update Seashore with the changes
	rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	[[document helpers] activeLayerChanged:kLayerDeleted rect:&rect];
	
	// Unset the clone tool
	[[[document tools] getTool:kCloneTool] unset];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] restoreLayer:index fromLostIndex:[deletedLayers count] - 1];
	
	// Update toolbox
	if ([layer floating])
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:YES];
}

- (void)restoreLayer:(NSInteger)index fromLostIndex:(NSInteger)lostIndex
{
	id layer = deletedLayers[lostIndex];
	NSArray *tempArray;
	IntRect rect;
	int i;
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Decompress the layer we are restoring
	[layer decompress];
	
	// Create a new array with all the existing layers including the one being restored
	tempArray = @[];
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == index) {
			tempArray = [tempArray arrayByAddingObject:layer];
		}
		else {
			tempArray = [tempArray arrayByAddingObject:layers[(i > index) ? i - 1 : i]];
		}
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Create a new array of lost layers with the removed layer replaced with "BLANK"
	tempArray = @[];
	for (i = 0; i < [deletedLayers count]; i++) {
		if (i == lostIndex)
			tempArray = [tempArray arrayByAddingObject:@"BLANK"];
		else
			tempArray = [tempArray arrayByAddingObject:deletedLayers[i]];
	}
	
	// Now substitute in our new array
	deletedLayers = tempArray;
	
	// Update Seashore with the changes
	activeLayerIndex = index;
		
	// Wrap selection to the opaque if the layer is a floating one
	if ([layer floating])
		[[document selection] selectOpaque];
		
	// Update Seashore with the changes
	rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	[[document helpers] activeLayerChanged:kLayerAdded rect:&rect];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:index];
	
	// Update toolbox
	if ([layer floating]){
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] floatTool];
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:YES];
	}
}

- (void)makeSelectionFloat:(BOOL)duplicate
{
	NSArray *tempArray = @[];
	BOOL containsNothing;
	unsigned char *data;
	IntRect rect;
	id layer;
	int i, spp = [[document contents] spp];
	
	// Check the state is valid
	if (![[document selection] active] || [[document selection] floating])
		return;
	
	// Save the existing selection
	rect = [[document selection] globalRect];
	data = [[document selection] selectionData:NO];
	
	// Check that the selection contains something
	containsNothing = YES;
	for (i = 0; containsNothing && (i < rect.size.width * rect.size.height); i++) {
		if (data[(i + 1) * spp - 1] != 0x00)
			containsNothing = NO;
	}
	if (containsNothing) {
		free(data);
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = LOCALSTR(@"empty selection title", @"Selection empty");
		alert.informativeText = LOCALSTR(@"empty selection body", @"The selection cannot be floated since it is empty.");
		[alert runModal];
		return;
	}

	// Remove the old selection if we're not duplicating
	if(!duplicate)
		[[document selection] deleteSelection];
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Create a new array with all the existing layers and the one being added
	layer = [[SeaLayer alloc] initFloatingWithDocument:document rect:rect data:data];
	[layer trimLayer];
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == activeLayerIndex)
			tempArray = [tempArray arrayByAddingObject:layer];
		else
			tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
		
	// Wrap selection to the opaque
	[[document selection] selectOpaque];
	
	// Inform document of layer change
	[[document helpers] activeLayerChanged:kLayerAdded rect:&rect];
	
	// Inform the tools of the floating
	[[[SeaController utilitiesManager] toolboxUtilityFor:document] floatTool];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];
}

-(IBAction)duplicate:(id)sender
{
	[self makeSelectionFloat:YES];	
}

-(void)toggleFloatingSelection
{	
	if ([[document selection] floating]) {
		[self anchorSelection];
	}
	else {
		[self makeSelectionFloat:NO];
	}
}

- (void)makePasteboardFloat
{
	NSArray *tempArray = @[];
	NSString *imageRepDataType;
	NSData *imageRepData;
	NSBitmapImageRep *imageRep;
	IntRect rect;
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	id layer;
	unsigned char *data, *tdata;
	NSInteger i, spp = [[document contents] spp], sspp, dspp;
	BMPColorSpace space;
	ColorSyncProfileRef cmProfileLoc = NULL;
	NSInteger bipp, bypr, bps;
	//NSData *profile = nil;
	NSPoint centerPoint;
	IntPoint sel_point;
	IntSize sel_size;
	
	// Check the state is valid
	if ([[document selection] floating])
		return;
	
	// Get the data from the pasteboard
	imageRepDataType = [pboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
	//if (imageRepDataType == NULL) {
	//	imageRepDataType = [pboard availableTypeFromArray:@[NSPICTPboardType]];
	//	imageRepData = [pboard dataForType:imageRepDataType];
	//	image = [[NSImage alloc] initWithData:imageRepData];
	//	imageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	//}
	//else {
		imageRepData = [pboard dataForType:imageRepDataType];
		imageRep = [[NSBitmapImageRep alloc] initWithData:imageRepData];
	//}
	
	// Determine the color space of pasteboard image
	space = -1;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
		space = kGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
		space = kInvertedGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
		space = kRGBColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
		space = kCMYKColorSpace;
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		return;
	}
	
	// Do not extract color profile
	//profile = NULL;
	
	/*
	Here the reason we don't extract the profile data is because data on the pasteboard is already
	 in the proper color profile. By applying that profile again we're apparently double-converting.
	 There should be a better way to do this but this works for now.
	 
	 profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
	if (profile) {
		cmProfileLoc.locType = cmPtrBasedProfile;
		cmProfileLoc.u.ptrLoc.p = (Ptr)[profile bytes];
	}
	 */
	
	// Work out the correct center point
	sel_size = IntMakeSize((int)[imageRep pixelsWide], (int)[imageRep pixelsHigh]);
	if ([[document selection] selectionSizeMatch:sel_size]) {
		sel_point = [[document selection] selectionPoint];
		rect = IntMakeRect(sel_point.x, sel_point.y, sel_size.width, sel_size.height);
	}
	else if ((height > 64 && width > 64 && sel_size.height > height - 12 &&  sel_size.width > width - 12) || (sel_size.height >= height &&  sel_size.width >= width)) { 
		rect = IntMakeRect(width / 2 - sel_size.width / 2, height / 2 - sel_size.height / 2, sel_size.width, sel_size.height);
	}
	else {
		centerPoint = [(CenteringClipView *)[[document docView] superview] centerPoint];
		centerPoint.x /= [[document docView] zoom];
		centerPoint.y /= [[document docView] zoom];
		rect = IntMakeRect(centerPoint.x - sel_size.width / 2, centerPoint.y - sel_size.height / 2, sel_size.width, sel_size.height);
	}
	
	// Put it in a nice form
	sspp = [imageRep samplesPerPixel];
	bps = [imageRep bitsPerSample];
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
	dspp = spp;
	if (spp == 4 && selectedChannel == kAlphaChannel) {
		dspp = 2;
	}
	data = convertBitmapColorSync(dspp, (dspp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, [imageRep bitmapData], rect.size.width, rect.size.height, sspp, bipp, bypr, space, cmProfileLoc, bps, 0);
	if (!data) {
		NSLog(@"Required conversion not supported.");
		return;
	}
	unpremultiplyBitmap(dspp, data, data, rect.size.width * rect.size.height);
	
	// Handle the special case where a GGGA graphic is wanted
	if (spp == 4 && dspp == 2) {
		tdata = malloc(make_128(rect.size.width * rect.size.height * 4));
		for (i = 0; i < rect.size.width * rect.size.height; i++) {
			tdata[i * 4] = data[i * 2];
			tdata[i * 4 + 1] = data[i * 2];
			tdata[i * 4 + 2] = data[i * 2];
			tdata[i * 4 + 3] = data[i * 2 + 1];
		}
		free(data);
		data = tdata;
	}
	
	// Inform the helpers we will change the layer
	[[document helpers] activeLayerWillChange];
	
	// Create a new array with all the existing layers and the one being added
	layer = [[SeaLayer alloc] initFloatingWithDocument:document rect:rect data:data];
	[layer trimLayer];
	for (i = 0; i < [layers count] + 1; i++) {
		if (i == activeLayerIndex)
			tempArray = [tempArray arrayByAddingObject:layer];
		else
			tempArray = [tempArray arrayByAddingObject:(i > activeLayerIndex) ? layers[i - 1] : layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Wrap selection to the opaque
	[[document selection] selectOpaque];
	
	// Inform document of layer change
	[[document helpers] activeLayerChanged:kLayerAdded rect:&rect];
	
	// Inform the tools of the floating
	[[[SeaController utilitiesManager] toolboxUtilityFor:document] floatTool];
	
	// Make action undoable
	[(SeaContent *)[[document undoManager] prepareWithInvocationTarget:self] deleteLayer:activeLayerIndex];
}

- (void)anchorSelection
{
	unsigned char *data, *overlay;
	IntRect dataRect, layerRect;
	int i, j, destXPos, destYPos, spp = [self spp];
	int floatingLayerIndex = -1;
	id layer;
	
	// Don't do anything if there's no selection
	if (![[document selection] floating])
		return;
	
	// We need to figure out what layer is floating
	// This isn't nessisarily the current active layer since people can select different
	// layers while there is a floating layer.
	for(i = 0; i < [layers count]; i++){
		if([layers[i] floating]){
			if(floatingLayerIndex != -1){
				NSLog(@"Multiple floating layers?");
			}else {
				floatingLayerIndex = i;
			}
		}
	}
	
	if(floatingLayerIndex == -1){
		NSLog(@"There were no floating layers!");
	}
	// Save the existing selection
	layer = layers[floatingLayerIndex];
	dataRect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);;
	data = malloc(make_128(dataRect.size.width * dataRect.size.height * spp));
	memcpy(data, [(SeaLayer *)layer data], dataRect.size.width * dataRect.size.height * spp);
	
	// Delete the floating layer
	[self deleteLayer:floatingLayerIndex];
	
	// Work out the new layer rectangle
	layer = layers[activeLayerIndex];
	layerRect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
	
	// Copy the selection to the overlay
	overlay = [[document whiteboard] overlay];
	[[document whiteboard] setOverlayOpacity:255];
	for (j = 0; j < dataRect.size.height; j++) {
		for (i = 0; i < dataRect.size.width; i++) {
			destXPos = dataRect.origin.x - layerRect.origin.x + i;
			destYPos = dataRect.origin.y - layerRect.origin.y + j;
			if (destXPos >= 0 && destXPos < layerRect.size.width && destYPos >= 0 && destYPos < layerRect.size.height) {
				memcpy(&(overlay[(destYPos * layerRect.size.width + destXPos) * spp]), &(data[(j * dataRect.size.width + i) * spp]), spp);
			}
		}
	}
	free(data);
	
	// Clear the selection
	[[document selection] clearSelection];

	// We would inform the tools of the floating but this is already called in the deleteLayer method

	// Apply the overlay
	[(SeaHelpers *)[document helpers] applyOverlay];
}

- (BOOL)canRaise:(NSInteger)index
{
	if (index == kActiveLayer) index = activeLayerIndex;
	return !(index == 0);
}

- (BOOL)canLower:(NSInteger)index
{
	if (index == kActiveLayer) index = activeLayerIndex;
	if ([layers[index] floating] && index == [layers count] - 2) return NO;
	return !(index == [layers count] - 1);
}

- (void)moveLayer:(id)layer toIndex:(NSInteger)index
{
	[self moveLayerOfIndex:[layers indexOfObject:layer] toIndex: index];	
}

- (void)moveLayerOfIndex:(NSInteger)source toIndex:(NSInteger)dest
{
	NSMutableArray *tempArray;

	// An invalid destination
	if(dest < 0 || dest > [layers count])
		return;
	
	// Correct index
	if (source == kActiveLayer) source = activeLayerIndex;
	id activeLayer = layers[activeLayerIndex];
	
	// Allocate space for a new array
	tempArray = [layers mutableCopy];
	[tempArray removeObjectAtIndex:source];
	
	NSInteger actualFinal;
	
	if(dest >= [layers count]){
		actualFinal = [layers count] - 1;
	}else if(dest > source){
		actualFinal = dest - 1;
	}else{
		actualFinal = dest;
	}
	
	[tempArray insertObject:layers[source] atIndex:actualFinal];
	
	// Now substitute in our new array
	layers = [NSArray arrayWithArray:tempArray];
	
	// Update Seashore with the changes
	activeLayerIndex = [layers indexOfObject:activeLayer];
	[[document helpers] layerLevelChanged:activeLayerIndex];
	
	// For the undo we need to make sure we get the offset right
	if(source >= dest){
		source++;
	}
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] moveLayerOfIndex: actualFinal toIndex: source];
}


- (void)raiseLayer:(NSInteger)index
{
	NSArray *tempArray;
	int i;
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	
	// Do nothing if we can't do anything
	if (![self canRaise:index])
		return;
	
	// Allocate space for a new array
	tempArray = @[];
	
	// Go through and add all existing objects to the new array
	for (i = 0; i < [layers count]; i++) {
		if (i == index - 1) {
			tempArray = [tempArray arrayByAddingObject:layers[i + 1]];
			tempArray = [tempArray arrayByAddingObject:layers[i]];
			i++;
		}
		else
			tempArray = [tempArray arrayByAddingObject:layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Update Seashore with the changes
	activeLayerIndex = index - 1;
	[[document helpers] layerLevelChanged:activeLayerIndex];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] lowerLayer:index - 1];
}

- (void)lowerLayer:(NSInteger)index
{
	NSArray *tempArray;
	int i;
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	
	// Do nothing if we can't do anything
	if (![self canLower:index])
		return;
	
	// Allocate space for a new array
	tempArray = @[];
	
	// Go through and add all existing objects to the new array
	for (i = 0; i < [layers count]; i++) {
		if (i == index) {
			tempArray = [tempArray arrayByAddingObject:layers[i + 1]];
			tempArray = [tempArray arrayByAddingObject:layers[i]];
			i++;
		}
		else
			tempArray = [tempArray arrayByAddingObject:layers[i]];
	}
	
	// Now substitute in our new array
	layers = tempArray;
	
	// Update Seashore with the changes
	activeLayerIndex = index + 1;
	[[document helpers] layerLevelChanged:activeLayerIndex];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] raiseLayer:index + 1];
}

- (void)clearAllLinks
{
	int i;
	
	// Go through all layers and toggle them back so they are unlinked
	for (i = 0; i < [layers count]; i++) {
		if ([layers[i] linked])
			[self setLinked: NO forLayer: i];
	}
}

- (void)setLinked:(BOOL)isLinked forLayer:(NSInteger)index
{
	id layer;
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	layer = layers[index];
	
	// Apply the changes
	[layer setLinked:isLinked];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] setLinked:!isLinked forLayer:index];
}

- (void)setVisible:(BOOL)isVisible forLayer:(NSInteger)index
{
	id layer;
	
	// Correct index
	if (index == kActiveLayer) index = activeLayerIndex;
	layer = layers[index];
	
	// Apply the changes
	[layer setVisible:isVisible];
	[[document helpers] layerAttributesChanged:index hold:YES];
	[(PegasusUtility *)[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] setVisible:!isVisible forLayer:index];
}

- (void)copyMerged
{
	id pboard = [NSPasteboard generalPasteboard];
	int spp = [[document contents] spp], i , j, k, t1;
	NSBitmapImageRep *imageRep;
	IntRect globalRect;
	unsigned char *data = [(SeaWhiteboard *)[document whiteboard] data];
	unsigned char *ndata = NULL;
	unsigned char *mask;

	// Check selection
	if ([[document selection] active]) {
		mask = [[document selection] mask];
		globalRect = [[document selection] globalRect];
		ndata = malloc(make_128(globalRect.size.width * globalRect.size.height * spp));
		if (mask) {
			for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++) {
				for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++) {
					for (k = 0; k < spp; k++) {
						ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  int_mult(data[(j * width + i) * spp + k], mask[(j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)], t1);
					}
				}
			}
		}
		else {
			for (j = globalRect.origin.y; j < globalRect.origin.y + globalRect.size.height; j++) {
				for (i = globalRect.origin.x; i < globalRect.origin.x + globalRect.size.width; i++) {
					for (k = 0; k < spp; k++) {
						ndata[((j - globalRect.origin.y) * globalRect.size.width + (i - globalRect.origin.x)) * spp + k] =  data[(j * width + i) * spp + k];
					}
				}
			}
		}
	}
	else {
		ndata = data;
		globalRect.origin.x = globalRect.origin.y = 0;
		globalRect.size.width = width;
		globalRect.size.height = height;
	}

	// Declare the data being added to the pasteboard
	[pboard declareTypes:@[NSPasteboardTypeTIFF] owner:NULL];
	
	// Add it to the pasteboard
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&ndata pixelsWide:globalRect.size.width pixelsHigh:globalRect.size.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:globalRect.size.width * spp bitsPerPixel:8 * spp];
	[pboard setData:[imageRep TIFFRepresentation] forType:NSPasteboardTypeTIFF]; 
	
	// Clean out the remains
	if (ndata != data) {
		free(ndata);
	}
}

- (BOOL)canFlatten
{
	// No, if there is a floating selection active
	if ([[document selection] floating])
		return NO;
	
	// Yes, if there are one or more layers
	if ([layers count] != 1)
		return YES;
	
	// Yes, if single layer is out of place
	if ([layers[0] xoff] != 0 || [layers[0] yoff] != 0
			|| [(SeaLayer *)layers[0] width] != width || [(SeaLayer *)layers[0] height] != height)
		return YES;
	
	return NO;
}

- (void)flatten
{
	[self merge:layers useRepresentation: YES withName: LOCALSTR(@"flattened", @"Flattened Layer")];
}

- (void)mergeLinked
{
	SeaLayer *layer;
	NSMutableArray *linkedLayers = [NSMutableArray array];
	// Go through noting each linked layer
	NSEnumerator *e = [layers objectEnumerator];
	while(layer = [e nextObject]) {
		if ([layer linked])
			[linkedLayers addObject: layer];
	}
	// Preform the merge
	[self merge:linkedLayers useRepresentation: NO withName: LOCALSTR(@"flattened", @"Flattened Layer")];
}

- (void)mergeDown
{
	// Make sure there is a layer to merge into
	if([self canLower:activeLayerIndex]){
		NSArray *twoLayers = @[layers[activeLayerIndex]];
		// Add the layer we're going into
		twoLayers = [twoLayers arrayByAddingObject:layers[activeLayerIndex + 1]];
		[self merge: twoLayers useRepresentation: NO withName: [layers[activeLayerIndex + 1] name]];
	}
}

- (void)merge:(NSArray *)mergingLayers useRepresentation:(BOOL)useRepresenation withName:(NSString *)newName
{
	CompositorOptions options;
	unsigned char *data;
	SeaLayer *layer, *lostLayer, *tempLayer = [SeaLayer alloc];
	int spp = [self spp];
	BOOL indexFound = NO;
	NSMutableArray *tempArray = [NSMutableArray array];
	IntRect rect = IntMakeRect(0,0,0,0);
	// The ordering dictionary is needed because layers which are linked are not
	// nessisarily contiguous -- thus just keeping a stack in the undo history
	// would not totally restore their state
	NSMutableDictionary *ordering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
	
	// Do nothing if we can't do anything
	if (![self canFlatten])
		return;
	
	// Inform the helpers we will flatten the document
	[[document helpers] documentWillFlatten];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:[layers count] andOrdering: ordering];
	[orderings addObject:ordering];
	// Create the replacement flat layer
	
	// Use representation is used when we want to use the pre-made image
	// representation of the image. Basicially, just when flattening the whole
	// file.
	if(useRepresenation){
		rect.size.width = width;
		rect.size.height = height;
		data = malloc(make_128(rect.size.width * rect.size.height * spp));
		memcpy(data, [(NSBitmapImageRep*)[[[document whiteboard] image] representations][0] bitmapData], rect.size.width * rect.size.height * spp);
		NSEnumerator *e = [layers objectEnumerator];
		while(layer = [e nextObject]){
			[ordering setValue: @([layers indexOfObject: layer]) forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
		}
		[tempArray addObject:tempLayer];
	}else{
		NSEnumerator *e = [layers objectEnumerator];
		// Here we find out the dimensions of the new layer, plus keep track of
		// which layers are not going to be merged (tempArray).
		while(layer = [e nextObject]) {
			[ordering setValue: @([layers indexOfObject: layer]) forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
			if([mergingLayers indexOfObject:layer] != NSNotFound){
				IntRect thisRect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
				rect = IntSumRects(rect, thisRect);
				if(!indexFound)
					[tempArray addObject:tempLayer];
			}else{
				[tempArray addObject:layer];
			}
		}
		data = malloc(make_128(rect.size.width * rect.size.height * spp));
		memset(data, 0, rect.size.width * rect.size.height * spp);
		// Set the composting options
		options.forceNormal = 0;
		options.rect = rect;
		options.destRect = rect;
		options.insertOverlay = NO;
		options.useSelection = NO;
		options.overlayOpacity = 255;
		options.overlayBehaviour = kNormalBehaviour;
		options.spp = spp;

		// Composite the linked layers
		NSEnumerator *f = [mergingLayers reverseObjectEnumerator];
		while(layer = [f nextObject])
			[[[document whiteboard] compositor] compositeLayer:layer withOptions:options andData: data];
	}
	unpremultiplyBitmap(spp, data, data, rect.size.width * rect.size.height);
	layer = [[SeaLayer alloc] initWithDocument:document rect:rect data:data spp:spp];
	[layer setName:[[NSString alloc] initWithString:newName]];

	// Get rid of all the other layers
	NSEnumerator *g = [mergingLayers objectEnumerator];
	while(lostLayer = [g nextObject])
		[layersToUndo addObject: lostLayer];
	
	// Revise layers
	activeLayerIndex = [tempArray indexOfObject:tempLayer];
	tempArray[activeLayerIndex] = layer;
	[tempArray removeObject:tempLayer];
	layers = tempArray;
	selectedChannel = 0;
	
	// Unset the clone tool
	[[[document tools] getTool:kCloneTool] unset];
	
	// Inform the helpers we have flattened the document
	[[document helpers] documentFlattened];
}

- (void)undoMergeWith:(NSInteger)oldNoLayers andOrdering: (NSMutableDictionary *)ordering
{
	NSMutableArray *oldLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
	NSMutableDictionary *newOrdering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
	int i;
	SeaLayer *layer;
	
	// Inform the helpers we will unflatten the document
	[[document helpers] documentWillFlatten];

	// Get the current orderings for the undo history
	NSEnumerator *e = [layers objectEnumerator];
	while(layer = [e nextObject])
		[newOrdering setValue: @([layers indexOfObject: layer]) forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] redoMergeWith:[layers count] andOrdering: newOrdering];

	// This is just to make the dimensions of the array correct
	while([oldLayers count] < oldNoLayers)
		[oldLayers addObject: [layers lastObject]];

	// Store the previous layers to their correct location in the array
	for(i = 0; i < oldNoLayers - [layers count] + 1; i++){
		SeaLayer *oldLayer = [layersToUndo lastObject];
		[layersToUndo removeLastObject];
		int replInd = [ordering[[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]] intValue];		
		oldLayers[replInd] = oldLayer;
	}
	
	for(i = 0; i < [layers count]; i++){
		SeaLayer *oldLayer = layers[i];
		NSNumber *oldIndex = ordering[[NSString stringWithFormat:@"%d", [oldLayer uniqueLayerID]]];
		// We also will need to store the merged layer for redo
		if(oldIndex != nil)
			oldLayers[[oldIndex intValue]] = oldLayer;
		else
			[layersToRedo addObject:oldLayer];
	}
	
	// Empty the layers array
	layers = oldLayers;
	
	// Unset the clone tool
	[[[document tools] getTool:kCloneTool] unset];
	
	// Inform the helpers we have unflattened the document
	[[document helpers] documentFlattened];
	
	[orderings removeObject: ordering];
	[orderings addObject:newOrdering];
}

- (unsigned char *)bitmapUnderneath:(IntRect)rect
{
	CompositorOptions options;
	unsigned char *data;
	SeaLayer *layer;
	NSInteger i;
	int spp = [self spp];
	
	// Create the replacement flat layer
	data = malloc(make_128(rect.size.width * rect.size.height * spp));
	memset(data, 0, rect.size.width * rect.size.height * spp);

	// Set the composting options
	options.forceNormal = 0;
	options.rect = rect;
	options.destRect = rect;
	options.insertOverlay = NO;
	options.useSelection = NO;
	options.overlayOpacity = 255;
	options.overlayBehaviour = kNormalBehaviour;
	options.spp = spp;

	// Composite the layers underneath
	for (i = [layers count] - 1; i >= activeLayerIndex; i--) {
		layer = layers[i];
		if ([layer visible]) {
			[[[document whiteboard] compositor] compositeLayer:layer withOptions:options andData:data];
		}
	}
	
	return data;
}

- (void)redoMergeWith:(NSInteger)oldNoLayers andOrdering:(NSMutableDictionary *)ordering
{
	NSMutableArray *newLayers = [NSMutableArray arrayWithCapacity:oldNoLayers];
	NSMutableDictionary *oldOrdering = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
	int i;
	SeaLayer *layer;
	
	// Inform the helpers we will flatten the document
	[[document helpers] documentWillFlatten];
	
	// Store the orderings
	NSEnumerator *e = [layers objectEnumerator];
	while(layer = [e nextObject])
		[oldOrdering setValue: @([layers indexOfObject: layer]) forKey: [NSString stringWithFormat: @"%d" ,[layer uniqueLayerID]]];

	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] undoMergeWith:[layers count] andOrdering:oldOrdering];

	// Populate the array
	while([newLayers count] < oldNoLayers)
		[newLayers addObject: [layers lastObject]];
	
	SeaLayer *newLayer = [layersToRedo lastObject];
	[layersToRedo removeLastObject];
	newLayers[[ordering[[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]] intValue]] = newLayer;

	// Go through and insert the layers at the appropriate places
	for(i = 0; i < [layers count]; i++){
		SeaLayer *newLayer = layers[i];
		NSNumber *newIndex = ordering[[NSString stringWithFormat:@"%d", [newLayer uniqueLayerID]]];
		if(newIndex != nil)
			newLayers[[newIndex intValue]] = newLayer;
		else
			[layersToUndo addObject:newLayer];
	}
	
	// Empty the layers array
	layers = newLayers;


	// Unset the clone tool
	[[[document tools] getTool:kCloneTool] unset];
	
	// Inform the helpers we have flattened the document
	[[document helpers] documentFlattened];

	[orderings removeObject:ordering];
	[orderings addObject:oldOrdering];
}

- (void)convertToType:(int)newType
{
	IndiciesRecord record;
	id layer;
	
	// Do nothing if there is nothing to do
	if (newType == type)
		return;
	
	// Make action undoable
	record.length = [layers count];
	record.indicies = malloc([layers count] * sizeof(int));
	for (NSInteger i = 0; i < [layers count]; i++) {
		layer = layers[i]; 
		record.indicies[i] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(SeaLayer *)layer width], [(SeaLayer *)layer height]) automatic:NO];
	}
	addToKeeper(&keeper, record);
	
	[[[document undoManager] prepareWithInvocationTarget:self] revertToType:type withRecord:record];
	
	// Go through and convert all layers to the new given type
	for (SeaLayer *layer in layers)
		[layer convertFromType:type to:newType];
		
	// Then save the new type
	type = newType;
	
	// Update everything
	[[document helpers] typeChanged]; 
}

- (void)revertToType:(int)newType withRecord:(IndiciesRecord)record
{
	NSInteger i;
	
	// Make action undoable
	[[[document undoManager] prepareWithInvocationTarget:self] convertToType:type];
	
	// Go through and convert all layers to the new given type
	for (SeaLayer *layer in layers) {
		[layer convertFromType:type to:newType];
	}

	// Then save the new type
	type = newType;
	
	// Restore the layers
	for (i = 0; i < [layers count]; i++)
		[[layers[i] seaLayerUndo] restoreSnapshot:record.indicies[i] automatic:NO];
	
	// Update everything
	[[document helpers] typeChanged]; 
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if (![[document selection] active])
		return NO;

	if([[theItem itemIdentifier] isEqual: FloatAnchorToolbarItemIdentifier]){
		if ([[document selection] floating]){
			[theItem setLabel: @"Anchor"];
			[theItem setPaletteLabel: LOCALSTR(@"anchor selection", @"Anchor Selection")];
			[theItem setImage:[NSImage imageNamed:@"anchor-tb"]];
		}else{
			[theItem setLabel:@"Float"];
			[theItem setPaletteLabel:LOCALSTR(@"float selection", @"Float Selection")];
			[theItem setImage:[NSImage imageNamed:@"float-tb"]];
		}
	}else if([[theItem itemIdentifier] isEqual: DuplicateSelectionToolbarItemIdentifier]){
		if([[document selection]floating])
			return NO;
	}
	
	return YES;
}
#endif

@end
