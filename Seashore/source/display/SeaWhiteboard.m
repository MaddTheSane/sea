#include <math.h>
#include <tgmath.h>
#import "SeaWhiteboard.h"
#import "StandardMerge.h"
#import "SeaLayer.h"
#if MAIN_COMPILE
#import "SeaDocument.h"
#endif
#import "SeaContent.h"
#import "SeaLayer.h"
#if MAIN_COMPILE
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "SeaSelection.h"
#endif
#import "Bitmap.h"
#if MAIN_COMPILE
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#endif

extern BOOL useAltiVec;

extern IntPoint gScreenResolution;

@implementation SeaWhiteboard
@synthesize overlayBehaviour;
@synthesize overlayOpacity;
@synthesize compositor;

#if MAIN_COMPILE
- (instancetype)initWithDocument:(id)doc
{
	if (self = [super init]) {
		ColorSyncProfileRef destProf;
		int layerWidth, layerHeight;
		NSString *pluginPath;
		NSBundle *bundle;
		
		// Remember the document we are representing
		document = doc;
		
		// Initialize the compostior
		compositor = NULL;
		if (useAltiVec) {
			pluginPath = [NSString stringWithFormat:@"%@/CompositorAV.bundle", [gMainBundle builtInPlugInsPath]];
			if ([gFileManager fileExistsAtPath:pluginPath]) {
				bundle = [NSBundle bundleWithPath:pluginPath];
				if (bundle && [bundle principalClass]) {
					compositor = [[bundle principalClass] alloc];
				}
			}
		}
		compositor = [[SeaCompositor alloc] initWithDocument:document];
		
		// Record the width, height and use of greys
		width = [(SeaContent *)[document contents] width];
		height = [(SeaContent *)[document contents] height];
		layerWidth = [(SeaLayer *)[[document contents] activeLayer] width];
		layerHeight = [(SeaLayer *)[[document contents] activeLayer] height];
		
		// Record the samples per pixel used by the whiteboard
		spp = [[document contents] spp];
		
		// Set the view type to show all channels
		viewType = kAllChannelsView;
		CMYKPreview = NO;
		
		// Allocate the whiteboard data
		data = malloc(make_128(width * height * spp));
		overlay = malloc(make_128(layerWidth * layerHeight * spp));
		memset(overlay, 0, layerWidth * layerHeight * spp);
		replace = malloc(make_128(layerWidth * layerHeight));
		memset(replace, 0, layerWidth * layerHeight);
		altData = NULL;
		
		// Create the colour world
		displayProf = ColorSyncProfileCreateWithDisplayID(0);
		cgDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(displayProf);
		destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile);
		NSArray<NSDictionary<NSString*,id>*>*
		profSeq = @[
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)displayProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
					  },
					
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
					  },
					];
		
		cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
		
		CFRelease(destProf);
		
		// Set the locking thread to NULL
		lockingThread = NULL;
	}
	return self;
}
#else
- (instancetype)initWithContent:(SeaContent *)cont
{
	if (self = [super init]) {
		ColorSyncProfileRef destProf;
		int layerWidth, layerHeight;
		
		gScreenResolution = IntMakePoint(1024, 768);
		// Remember the document we are representing
		contents = cont;
		
		// Initialize the compostior
		compositor = NULL;
		
		if (compositor == NULL)
			compositor = [[SeaCompositor alloc] initWithContents:contents andWhiteboard:self];
		
		// Record the width, height and use of greys
		width = [contents width];
		height = [contents height];
		layerWidth = [(SeaLayer *)[contents activeLayer] width];
		layerHeight = [(SeaLayer *)[contents activeLayer] height];
		
		// Record the samples per pixel used by the whiteboard
		spp = [contents spp];
		
		// Set the view type to show all channels
		viewType = kAllChannelsView;
		CMYKPreview = NO;
		
		// Allocate the whiteboard data
		data = malloc(make_128(width * height * spp));
		overlay = malloc(make_128(layerWidth * layerHeight * spp));
		memset(overlay, 0, layerWidth * layerHeight * spp);
		replace = malloc(make_128(layerWidth * layerHeight));
		memset(replace, 0, layerWidth * layerHeight);
		altData = NULL;
		
		// Create the colour world
		displayProf = ColorSyncProfileCreateWithDisplayID(0);
		cgDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(displayProf);
		destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile);
		NSArray<NSDictionary<NSString*,id>*>*
		profSeq = @[
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)displayProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
					  },
					
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
					  },
					];
		
		cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
		
		CFRelease(destProf);
		
		// Set the locking thread to NULL
		lockingThread = NULL;
	}
	return self;
}
#endif

- (void)dealloc
{	
	// Free the room we took for everything else
	if (displayProf) CFRelease(displayProf);
	if (cgDisplayProf) CGColorSpaceRelease(cgDisplayProf);
	if (cw) CFRelease(cw);
	if (data) free(data);
	if (overlay) free(overlay);
	if (replace) free(replace);
	if (altData) free(altData);
}

- (IntRect)applyOverlay
{
	id layer;
	int leftOffset, rightOffset, topOffset, bottomOffset;
	int i, j, k, srcLoc, selectedChannel;
	int xoff, yoff;
	unsigned char *srcPtr;
	int lwidth, lheight, selectOpacity;
	IntRect rect, selectRect;
	BOOL overlayOkay, overlayReplacing;
	IntPoint maskOffset, trueMaskOffset;
#if MAIN_COMPILE
	IntSize maskSize;
	IntPoint point;
	int t1;
	unsigned char *mask;
#endif
	BOOL floating;
	
	// Fill out the local variables
#if MAIN_COMPILE
	selectRect = [[document selection] localRect];
	selectedChannel = [[document contents] selectedChannel];
	layer = [[document contents] activeLayer];
#else
	selectedChannel = [contents selectedChannel];
	layer = [contents activeLayer];
#endif
	floating = [layer floating];
	srcPtr = [(SeaLayer *)layer data];
	lwidth = [(SeaLayer *)layer width];
	lheight = [(SeaLayer *)layer height];
	xoff = [layer xoff];
	yoff = [layer yoff];
#if MAIN_COMPILE
	mask = ([[document selection] mask]);
	maskOffset = [[document selection] maskOffset];
#endif
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
#if MAIN_COMPILE
	maskSize = [[document selection] maskSize];
#endif
	overlayReplacing = (overlayBehaviour == kReplacingBehaviour);
	
	// Calculate offsets
	leftOffset = lwidth + 1;
	rightOffset = -1;
	bottomOffset = -1;
	topOffset = lheight + 1;
	for (j = 0; j < lheight; j++) {
		for (i = 0; i < lwidth; i++) {	
			if (overlayReplacing) {
				if (replace[j * lwidth + i] != 0) {	
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
				else {
					overlay[(j * lwidth + i + 1) * spp - 1] = 0;
				}
			}
			else {
				if (overlay[(j * lwidth + i + 1) * spp - 1] != 0) {
					if (rightOffset < i + 1) rightOffset = i + 1;
					if (topOffset > j) topOffset = j;
					if (leftOffset > i) leftOffset = i;
					if (bottomOffset < j + 1) bottomOffset = j + 1;
				}
			}
		}
	}
	
	// If we didn't find any pixels, all of the offsets will be in their original
	// state, but we only need to test one ...
	if (leftOffset < 0) return IntMakeRect(0, 0, 0, 0);
	
	// Create the rectangle
	rect = IntMakeRect(leftOffset, topOffset, rightOffset - leftOffset, bottomOffset - topOffset);
	
#if MAIN_COMPILE
	// Allow the undo
	[[layer seaLayerUndo] takeSnapshot:rect automatic:YES];
#endif
	
	// Go through each column and row
	for (j = rect.origin.y; j < rect.origin.y + rect.size.height; j++) {
		for (i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
			
			// Determine the source location
			srcLoc = (j * lwidth + i) * spp;
			
			// Check if we should apply the overlay for this pixel
			overlayOkay = NO;
			switch (overlayBehaviour) {
				case kReplacingBehaviour:
				case kMaskingBehaviour:
					selectOpacity = replace[j * lwidth + i];
				break;
				default:
					selectOpacity = overlayOpacity;
				break;
			}
#if MAIN_COMPILE
			if ([[document selection] active]) {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					overlayOkay = YES;
					if (mask && !floating)
						selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
				}
			}
			else {
				overlayOkay = YES;
			}
#else
			overlayOkay = YES;
#endif
			
			// Don't do anything if there's no point
			if (selectOpacity == 0)
				overlayOkay = NO;
			
			// Apply the overlay
			if (overlayOkay) {
				if (selectedChannel == kAllChannels && !floating) {
					
					// For the general case
					switch (overlayBehaviour) {
						case kErasingBehaviour:
							eraseMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						case kReplacingBehaviour:
							replaceMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							specialMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
				else if (selectedChannel == kPrimaryChannels || floating) {
				
					// For the primary channels
					switch (overlayBehaviour) {
						case kReplacingBehaviour:
							replacePrimaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							primaryMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity, NO);
						break;
					}
					
				}
				else if (selectedChannel == kAlphaChannel) {
					
					// For the alpha channels
					switch (overlayBehaviour) {
						case kReplacingBehaviour:
							replaceAlphaMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
						default:
							alphaMerge(spp, srcPtr, srcLoc, overlay, srcLoc, selectOpacity);
						break;
					}
					
				}
			}
			
			// Clear the overlay
			for (k = 0; k < spp; k++)
				overlay[srcLoc + k] = 0;
			replace[j * lwidth + i] = 0;
			
		}
	}
	
	// Put the rectangle in the document's co-ordinates
	rect.origin.x += xoff;
	rect.origin.y += yoff;
	
	// Reset the overlay's opacity and behaviour
	overlayOpacity = 0;
	overlayBehaviour = kNormalBehaviour;
	
	return rect;
}

- (void)clearOverlay
{
	SeaLayer *layer =
#if MAIN_COMPILE
	[[document contents] activeLayer];
#else
	[contents activeLayer];
#endif

	memset(overlay, 0, [layer width] * [layer height] * spp);
	memset(replace, 0, [layer width] * [layer height]);
	overlayOpacity = 0;
	overlayBehaviour = kNormalBehaviour;
}

- (unsigned char *)overlay
{
	return overlay;
}

- (unsigned char *)replace
{
	return replace;
}

- (BOOL)whiteboardIsLayerSpecific
{
	return viewType == kPrimaryChannelsView || viewType == kAlphaChannelView;
}

- (void)readjust
{	
#if MAIN_COMPILE
	// Resize the memory allocated to the data
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	
	// Change the samples per pixel if required
	if (spp != [[document contents] spp]) {
		spp = [[document contents] spp];
		viewType = kAllChannelsView;
		CMYKPreview = NO;
	}
#else
	// Resize the memory allocated to the data
	width = [contents width];
	height = [contents height];
	
	// Change the samples per pixel if required
	if (spp != [contents spp]) {
		spp = [contents spp];
		viewType = kAllChannelsView;
		CMYKPreview = NO;
	}
#endif
	
	// Revise the data
	if (data) free(data);
	data = malloc(make_128(width * height * spp));

	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
#if MAIN_COMPILE
	overlay = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp);
#else
	overlay = malloc(make_128([(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height] * spp);
#endif
	if (replace) free(replace);
	
#if MAIN_COMPILE
	replace = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]);
#else
	replace = malloc(make_128([(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height]);
#endif

	// Update ourselves
	[self update];
}

- (void)readjustLayer
{
	// Adjust the alternate data as necessary
	[self readjustAltData:NO];
	
	// Update the overlay
	if (overlay) free(overlay);
#if MAIN_COMPILE
	overlay = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height] * spp);
#else
	overlay = malloc(make_128([(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height] * spp));
	memset(overlay, 0, [(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height] * spp);
#endif
	
	if (replace) free(replace);
#if MAIN_COMPILE
	replace = malloc(make_128([(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[[document contents] activeLayer] width] * [(SeaLayer *)[[document contents] activeLayer] height]);
#else
	replace = malloc(make_128([(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height]));
	memset(replace, 0, [(SeaLayer *)[contents activeLayer] width] * [(SeaLayer *)[contents activeLayer] height]);
#endif
	
	// Update ourselves
	[self update];
}

- (void)readjustAltData:(BOOL)update
{
#if MAIN_COMPILE
	id contents = [document contents];
#endif
	int selectedChannel = [contents selectedChannel];
	BOOL trueView = [contents trueView];
	id layer;
	int xwidth, xheight;
	
	// Free existing data
	viewType = kAllChannelsView;
	if (altData) free(altData);
	altData = NULL;
	
	// Change layer if appropriate
#if MAIN_COMPILE
	if ([[document selection] floating]) {
		layer = [contents layer:[contents activeLayerIndex] + 1];
	} else {
		layer = [contents activeLayer];
	}
#else
	layer = [contents activeLayer];
#endif
	
	// Create room for alternative data if necessary
	if (!trueView && selectedChannel == kPrimaryChannels) {
		viewType = kPrimaryChannelsView;
		xwidth = [(SeaLayer *)layer width];
		xheight = [(SeaLayer *)layer height];
		altData = malloc(make_128(xwidth * xheight * (spp - 1)));
	}
	else if (!trueView && selectedChannel == kAlphaChannel) {
		viewType = kAlphaChannelView;
		xwidth = [(SeaLayer *)layer width];
		xheight = [(SeaLayer *)layer height];
		altData = malloc(make_128(xwidth * xheight));
	}
	else if (CMYKPreview && spp == 4) {
		viewType = kCMYKPreviewView;
		xwidth = [(SeaContent *)contents width];
		xheight = [(SeaContent *)contents height];
		altData = malloc(make_128(xwidth * xheight * 4));
	}
	
	// Update ourselves (if advised to)
	if (update)
		[self update];
}

- (BOOL)CMYKPreview
{
	return CMYKPreview;
}

- (BOOL)canToggleCMYKPreview
{
	return spp == 4;
}

- (void)toggleCMYKPreview
{
	// Do nothing if we can't do anything
	if (![self canToggleCMYKPreview])
		return;
		
	// Otherwise make the change
	CMYKPreview = !CMYKPreview;
	[self readjustAltData:YES];
#if MAIN_COMPILE
	[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
#endif
}

- (NSColor *)matchColor:(NSColor *)color
{
	NSColor *result;
	
	// Determine the RGB color
	float srcColor[] = {color.redComponent, color.greenComponent, color.blueComponent};
	float dstColor[4] = {0};
	
	// Match color
	ColorSyncTransformConvert(cw, 1, 1, dstColor, kColorSync32BitFloat, kColorSyncAlphaNone | kColorSyncByteOrderDefault, sizeof(dstColor), srcColor, kColorSync32BitFloat, kColorSyncAlphaNone | kColorSyncByteOrderDefault, sizeof(srcColor), NULL);
	
	// Calculate result
	result = [NSColor colorWithDeviceCyan:dstColor[0] magenta:dstColor[1] yellow:dstColor[2] black:dstColor[3] alpha:[color alphaComponent]];
	
	return result;
}

- (void)forcedChannelUpdate
{
	id layer;
	int layerWidth, layerHeight, lxoff, lyoff;
	unsigned char *layerData, tempSpace[4], tempSpace2[4], *mask, *floatingData;
	int i, j, k, temp, tx, ty, t, selectOpacity, nextOpacity;
	IntRect selectRect, minorUpdateRect;
	IntSize maskSize = IntMakeSize(0, 0);
	IntPoint point, maskOffset = IntMakePoint(0, 0);
	BOOL useSelection, floating;
#if MAIN_COMPILE
	id flayer;
#endif
	
	// Prepare variables for later use
	mask = NULL;
	selectRect = IntMakeRect(0, 0, 0, 0);
#if MAIN_COMPILE
	useSelection = [[document selection] active];
	floating = [[document selection] floating];
	floatingData = [(SeaLayer *)[[document contents] activeLayer] data];
	if (useSelection && floating) {
		layer = [[document contents] layer:[[document contents] activeLayerIndex] + 1];
	}
	else {
		layer = [[document contents] activeLayer];
	}
	if (useSelection) {
		if (floating) {
			flayer = [[document contents] activeLayer];
			selectRect = IntMakeRect([(SeaLayer *)flayer xoff] - [(SeaLayer *)layer xoff], [(SeaLayer *)flayer yoff] - [(SeaLayer *)layer yoff], [(SeaLayer *)flayer width], [(SeaLayer *)flayer height]);
		}
		else {
			selectRect = [[document selection] globalRect];
		}
		mask = ([[document selection] mask]);
		maskOffset = [[document selection] maskOffset];
		maskSize = [[document selection] maskSize];
	}
#else
	floatingData = [(SeaLayer *)[contents activeLayer] data];
	layer = [contents activeLayer];
#endif
	selectOpacity = 255;
	layerWidth = [(SeaLayer *)layer width];
	layerHeight = [(SeaLayer *)layer height];
	lxoff = [(SeaLayer *)layer xoff];
	lyoff = [(SeaLayer *)layer yoff];
	layerData = [(SeaLayer *)layer data];
	
	// Determine the minor update rect
	if (useUpdateRect) {
		minorUpdateRect = updateRect;
		IntOffsetRect(&minorUpdateRect, -[layer xoff],  -[layer yoff]);
		minorUpdateRect = IntConstrainRect(minorUpdateRect, IntMakeRect(0, 0, layerWidth, layerHeight));
	}
	else {
		minorUpdateRect = IntMakeRect(0, 0, layerWidth, layerHeight);
	}
	
	// Go through pixel-by-pixel working out the channel update
	for (j = minorUpdateRect.origin.y; j < minorUpdateRect.origin.y + minorUpdateRect.size.height; j++) {
		for (i = minorUpdateRect.origin.x; i < minorUpdateRect.origin.x + minorUpdateRect.size.width; i++) {
			temp = j * layerWidth + i;
			
			// Determine what we are compositing to
			if (viewType == kPrimaryChannelsView) {
				for (k = 0; k < spp - 1; k++)
					tempSpace[k] = layerData[temp * spp + k];
				tempSpace[spp - 1] =  0xFF;
			}
			else {
				tempSpace[0] = layerData[(temp + 1) * spp - 1];
				tempSpace[1] =  0xFF;
			}
			
			// Make changes necessary if a selection is active
			if (useSelection) {
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					if (floating) {
						tx = i - selectRect.origin.x;
						ty = j - selectRect.origin.y;
						if (viewType == kPrimaryChannelsView) {
							memcpy(&tempSpace2, &(floatingData[(ty * selectRect.size.width + tx) * spp]), spp);
						}
						else {
							tempSpace2[0] = floatingData[(ty * selectRect.size.width + tx) * spp];
							tempSpace2[1] = floatingData[(ty * selectRect.size.width + tx + 1) * spp - 1];
						}
						normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, 255);
					}
					if (mask)
						selectOpacity = mask[(point.y - selectRect.origin.y - maskOffset.y) * maskSize.width + (point.x - selectRect.origin.x - maskOffset.x)];
				}
			}
			
			// Check for floating layer
			if (useSelection && floating) {
			
				// Insert the overlay
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect)) {
					tx = i - selectRect.origin.x;
					ty = j - selectRect.origin.y;
					if (selectOpacity > 0) {
						if (viewType == kPrimaryChannelsView) {
							memcpy(&tempSpace2, &(overlay[(ty * selectRect.size.width + tx) * spp]), spp);
							if (overlayOpacity < 255)
								tempSpace2[spp - 1] = int_mult(tempSpace2[spp - 1], overlayOpacity, t);
						}
						else {
							tempSpace2[0] = overlay[(ty * selectRect.size.width + tx) * spp];
							if (overlayOpacity == 255)
								tempSpace2[1] = overlay[(ty * selectRect.size.width + tx + 1) * spp - 1];
							else
								tempSpace2[1] = int_mult(overlay[(ty * selectRect.size.width + tx + 1) * spp - 1], overlayOpacity, t);
						}
						if (overlayBehaviour == kReplacingBehaviour) {
							nextOpacity = int_mult(replace[ty * selectRect.size.width + tx], selectOpacity, t); 
							replaceMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else if (overlayBehaviour ==  kMaskingBehaviour) {
							nextOpacity = int_mult(replace[ty * selectRect.size.width + tx], selectOpacity, t); 
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else {							
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
						}
					}
				}
				
			}
			else {
				
				// Insert the overlay
				point.x = i;
				point.y = j;
				if (IntPointInRect(point, selectRect) || !useSelection) {
					if (selectOpacity > 0) {
						if (viewType == kPrimaryChannelsView) {
							memcpy(&tempSpace2, &(overlay[temp * spp]), spp);
							if (overlayOpacity < 255)
								tempSpace2[spp - 1] = int_mult(tempSpace2[spp - 1], overlayOpacity, t);
						}
						else {
							tempSpace2[0] = overlay[temp * spp];
							if (overlayOpacity == 255)
								tempSpace2[1] = overlay[(temp + 1) * spp - 1];
							else
								tempSpace2[1] = int_mult(overlay[(temp + 1) * spp - 1], overlayOpacity, t);
						}
						if (overlayBehaviour == kReplacingBehaviour) {
							nextOpacity = int_mult(replace[temp], selectOpacity, t); 
							replaceMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else if (overlayBehaviour ==  kMaskingBehaviour) {
							nextOpacity = int_mult(replace[temp], selectOpacity, t); 
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, nextOpacity);
						}
						else
							normalMerge((viewType == kPrimaryChannelsView) ? spp : 2, tempSpace, 0, tempSpace2, 0, selectOpacity);
					}
				}
				
			}
			
			// Finally update the channel
			if (viewType == kPrimaryChannelsView) {
				for (k = 0; k < spp - 1; k++)
					altData[temp * (spp - 1) + k] = tempSpace[k];
			}
			else {
				altData[j * layerWidth + i] = tempSpace[0];
			}
			
		}
	}
}

- (void)forcedCMYKUpdate:(IntRect)majorUpdateRect
{
	unsigned char *tempData;
	int i;

	// Define the source
	if (useUpdateRect) {
		for (i = 0; i < majorUpdateRect.size.height; i++) {
		
			// Define the source
			tempData = malloc(majorUpdateRect.size.width * 3);
			stripAlphaToWhite(4, tempData, data + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * 4, majorUpdateRect.size.width);
			
			// Execute the conversion
			ColorSyncTransformConvert(cw, majorUpdateRect.size.width, 1, (char *)altData + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * 4, kColorSync8BitInteger, kColorSyncAlphaNone | kColorSyncByteOrderDefault, majorUpdateRect.size.width * 4, tempData, kColorSync8BitInteger, kColorSyncAlphaNone | kColorSyncByteOrderDefault, majorUpdateRect.size.width * 3, NULL);
			
			// Clean up after ourselves
			free(tempData);
			
		}
	}
	else {
	
		// Define the source
		tempData = malloc(width * height * 3);
		stripAlphaToWhite(4, tempData, data, width * height);
		
		// Execute the conversion
		ColorSyncTransformConvert(cw, width, height, altData, kColorSync8BitInteger, kColorSyncAlphaNone | kColorSyncByteOrderDefault, width * 4, tempData, kColorSync8BitInteger, kColorSyncAlphaNone | kColorSyncByteOrderDefault, width * 3, NULL);

		// Clean up after ourselves
		free(tempData);

	}
}

- (void)forcedUpdate
{
	NSInteger i, count = 0, layerCount =
#if MAIN_COMPILE
	[[document contents] layerCount];
#else
	[contents layerCount];
#endif
	IntRect majorUpdateRect;
	CompositorOptions options;
#if MAIN_COMPILE
	BOOL floating;
#endif
	
	// Determine the major update rect
	if (useUpdateRect) {
		majorUpdateRect = IntConstrainRect(updateRect, IntMakeRect(0, 0, width, height));
	}
	else {
		majorUpdateRect = IntMakeRect(0, 0, width, height);
	}
	
	// Handle non-channel updates here
	if (majorUpdateRect.size.width > 0 && majorUpdateRect.size.height > 0) {
		
		// Clear the whiteboard
		for (i = 0; i < majorUpdateRect.size.height; i++)
			memset(data + ((majorUpdateRect.origin.y + i) * width + majorUpdateRect.origin.x) * spp, 0, majorUpdateRect.size.width * spp);
			
		// Determine how many layers are visible
		for (i = 0; count < 2 && i < layerCount; i++) {
#if MAIN_COMPILE
			if ([[[document contents] layer:i] visible])
				count++;
#else
			if ([[contents layer:i] visible])
				count++;
#endif
		}
		
		// Set the composting options
		options.spp = spp;
		options.forceNormal = (count == 1);
		options.rect = majorUpdateRect;
		options.destRect = IntMakeRect(0, 0, width, height);
		options.overlayOpacity = overlayOpacity;
		options.overlayBehaviour = overlayBehaviour;
		options.useSelection = NO;
		
#if MAIN_COMPILE
		if ([[document selection] floating]) {
	
			// Go through compositing each visible layer
			for (i = layerCount - 1; i >= 0; i--) {
				if (i >= 1) floating = [[[document contents] layer:i - 1] floating];
				else floating = NO;
				if ([[[document contents] layer:i] visible]) {
					options.insertOverlay = floating;
					if (floating)
						[compositor compositeLayer:[[document contents] layer:i] withFloat:[[document contents] layer:i - 1] andOptions:options];
					else
						[compositor compositeLayer:[[document contents] layer:i] withOptions:options];
				}
				if (floating) i--;
			}
			
		}
		else {

			// Go through compositing each visible layer
			for (i = layerCount - 1; i >= 0; i--) {
				if ([[[document contents] layer:i] visible]) {
					options.insertOverlay = (i == [[document contents] activeLayerIndex]);
					options.useSelection = (i == [[document contents] activeLayerIndex]) && [[document selection] active];
					[compositor compositeLayer:[[document contents] layer:i] withOptions:options];
				}
			}
			
		}
#else
		// Go through compositing each visible layer
		for (i = layerCount - 1; i >= 0; i--) {
			if ([[contents layer:i] visible]) {
				options.insertOverlay = (i == [contents activeLayerIndex]);
				options.useSelection = NO;
				[compositor compositeLayer:[contents layer:i] withOptions:options];
			}
		}
	
#endif
		
	}
	
	// Handle channel updates here
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
		[self forcedChannelUpdate];
	}
	
	// If the user has requested a CMYK preview take the extra steps necessary
	if (viewType == kCMYKPreviewView) {
		[self forcedCMYKUpdate:majorUpdateRect];
	}
}

- (void)update
{
	useUpdateRect = NO;
	[self forcedUpdate];
#if MAIN_COMPILE
	[[document docView] setNeedsDisplay:YES];
#endif
}

- (void)update:(IntRect)rect inThread:(BOOL)thread
{
	NSRect displayUpdateRect = IntRectMakeNSRect(rect);
#if MAIN_COMPILE
	float zoom = [[document docView] zoom];
	int xres = [[document contents] xres], yres = [[document contents] yres];
#else
	float zoom = 1.0; // [[document docView] zoom];
	int xres = [contents xres], yres = [contents yres];
#endif
	
	if (gScreenResolution.x != 0 && xres != gScreenResolution.x) {
		displayUpdateRect.origin.x /= ((float)xres / gScreenResolution.x);
		displayUpdateRect.size.width /= ((float)xres / gScreenResolution.x);
	}
	if (gScreenResolution.y != 0 && yres != gScreenResolution.y) {
		displayUpdateRect.origin.y /= ((float)yres / gScreenResolution.y);
		displayUpdateRect.size.height /= ((float)yres / gScreenResolution.y);
	}
	displayUpdateRect.origin.x *= zoom;
	displayUpdateRect.size.width *= zoom;
	displayUpdateRect.origin.y *= zoom;
	displayUpdateRect.size.height *= zoom;
	
	// Free us from hairlines
	displayUpdateRect.origin.x = floor(displayUpdateRect.origin.x);
	displayUpdateRect.origin.y = floor(displayUpdateRect.origin.y);
	displayUpdateRect.size.width = ceil(displayUpdateRect.size.width) + 1.0;
	displayUpdateRect.size.height = ceil(displayUpdateRect.size.height) + 1.0;
	
	// Now do the rest of the update
	useUpdateRect = YES;
	updateRect = rect;
	[self forcedUpdate];
#if MAIN_COMPILE
	if (thread) {
		threadUpdateRect = displayUpdateRect;
		[[document docView] lockFocus];
		[NSBezierPath clipRect:threadUpdateRect];
		[[document docView] drawRect:threadUpdateRect];
		//[[NSGraphicsContext currentContext] flushGraphics];
		[[document docView] setNeedsDisplayInRect:displayUpdateRect];
		[[document docView] unlockFocus];
	}
	else {
		[[document docView] setNeedsDisplayInRect:displayUpdateRect];
	}
#endif
}

- (void)updateColorWorld
{
	ColorSyncProfileRef destProf;
	
	if (cw) CFRelease(cw);
	if (displayProf) CFRelease(displayProf);
	if (cgDisplayProf) CGColorSpaceRelease(cgDisplayProf);
	displayProf = ColorSyncProfileCreateWithDisplayID(0);
	cgDisplayProf = CGColorSpaceCreateWithPlatformColorSpace(displayProf);
	destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile);
	NSArray<NSDictionary<NSString*,id>*>*
	profSeq = @[
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)displayProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
				  },
				
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
				  },
				];
	
	cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
	
	CFRelease(destProf);
	if ([self CMYKPreview])
		[self update];
}

- (IntRect)imageRect
{
	SeaLayer *layer;
	
	if (viewType == kPrimaryChannelsView || viewType == kAlphaChannelView) {
#if MAIN_COMPILE
		if ([[document selection] floating])
			layer = [[document contents] layer:[[document contents] activeLayerIndex] + 1];
		else
			layer = [[document contents] activeLayer];
#else
		layer = [contents activeLayer];
#endif
		return IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
	}
	else {
		return IntMakeRect(0, 0, width, height);
	}
}

#if MAIN_COMPILE
- (NSImage *)image
{
	NSBitmapImageRep *imageRep;
	NSBitmapImageRep *altImageRep = NULL;
	id contents = [document contents];
	int xwidth, xheight;
	id layer;
	
	image = [[NSImage alloc] init];
	
	if (altData) {
		if ([[document selection] floating]) {
			layer = [contents layer:[contents activeLayerIndex] + 1];
		}
		else {
			layer = [contents activeLayer];
		}
		if (viewType == kPrimaryChannelsView) {
			xwidth = [(SeaLayer *)layer width];
			xheight = [(SeaLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:spp - 1 hasAlpha:NO isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:xwidth * (spp - 1) bitsPerPixel:8 * (spp - 1)];
		}
		else if (viewType == kAlphaChannelView) {
			xwidth = [(SeaLayer *)layer width];
			xheight = [(SeaLayer *)layer height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:xwidth * 1 bitsPerPixel:8];
		}
		else if (viewType == kCMYKPreviewView) {
			xwidth = [(SeaContent *)contents width];
			xheight = [(SeaContent *)contents height];
			altImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&altData pixelsWide:xwidth pixelsHigh:xheight bitsPerSample:8 samplesPerPixel:4 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceCMYKColorSpace bytesPerRow:xwidth * 4 bitsPerPixel:8 * 4];
		}
		[image addRepresentation:altImageRep];
	}
	else {
		imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
		[image addRepresentation:imageRep];
	}
	
	return image;
}
#endif

- (NSImage *)printableImage
{
	NSBitmapImageRep *imageRep;
	
	image = [[NSImage alloc] init];
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	[image addRepresentation:imageRep];
	
	return image;
}

- (unsigned char *)data
{
	return data;
}

- (unsigned char *)altData
{
	return altData;
}

- (CGColorSpaceRef)displayProf
{
	return cgDisplayProf;
}

@end
