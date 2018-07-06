#import "SeaCompositor.h"
#if MAIN_COMPILE
#import "SeaDocument.h"
#endif
#import "SeaWhiteboard.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#if MAIN_COMPILE
#import "SeaSelection.h"
#endif

@implementation SeaCompositor

#if MAIN_COMPILE
- (instancetype)initWithDocument:(id)doc
{
	if (self = [super init]) {
		int i;
		
		// Remember the document we are compositing for
		document = doc;
		
		// Work out the random table for the dissolve effect
		srandom(RANDOM_SEED);
		for (i = 0; i < 4096; i++)
			randomTable[i] = random() & 0xffffffff;
	}
	
	return self;
}
#else
- (instancetype)initWithContents:(SeaContent *)cont andWhiteboard:(SeaWhiteboard *)board
{
	if (self = [super init]) {
		int i;
		
		// Remember the document we are compositing for
		contents = cont;
		whiteboard = board;
		
		// Work out the random table for the dissolve effect
		srandom(RANDOM_SEED);
		for (i = 0; i < 4096; i++)
			randomTable[i] = (int)random();
	}
	return self;
}
#endif

- (void)compositeLayer:(SeaLayer *)layer withOptions:(CompositorOptions)options
{
	[self compositeLayer: layer withOptions: options andData: NULL];
}

- (void)compositeLayer:(SeaLayer *)layer withOptions:(CompositorOptions)options andData:(unsigned char *)destPtr
{
	int lwidth = [layer width], lheight = [layer height], mode = [layer mode];
#if MAIN_COMPILE
	unsigned char *mask;
	int opacity = [layer opacity];
	int selectedChannel = [[document contents] selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int t1;
	IntPoint point, maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
#else
	int opacity = [layer opacity], selectedChannel = [contents selectedChannel];
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
#endif
	unsigned char *srcPtr, *overlay, *replace;
	int startX, startY, endX, endY;
	int srcLoc, destLoc;
	unsigned char tempSpace[4], tempSpace2[4];
	BOOL insertOverlay, overlayOkay;
	BOOL floating;

	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
#if MAIN_COMPILE
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([[document contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([[document contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [[document selection] localRect];
	srcPtr = [layer data];
	if(!destPtr) destPtr = [[document whiteboard] data];
	overlay = [[document whiteboard] overlay];
	replace = [[document whiteboard] replace];
	mask = [[document selection] mask];
	maskOffset = [[document selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[document selection] maskSize];
	floating = [layer isFloating];
#else
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([contents width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([contents height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	//selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [(SeaLayer *)layer data];
	if(!destPtr) destPtr = [whiteboard data];
	overlay = [whiteboard overlay];
	replace = [whiteboard replace];
	//mask = [[document selection] mask];
	//maskOffset = [[document selection] maskOffset];
	//trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	//maskSize = [[document selection] maskSize];
	floating = [layer isFloating];
#endif
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Go through each row
	for (int j = startY; j < endY; j++) {
	
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(randomTable[(j + yoff) % 4096]);
			for (int k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (int i = startX; i < endX; i++) {
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (int k = 0; k < options.spp; k++)
				tempSpace2[k] = srcPtr[srcLoc + k];
			if (insertOverlay) {
				
				// Check if we should apply the overlay for this pixel
				overlayOkay = NO;
				switch (options.overlayBehaviour) {
					case SeaOverlayBehaviourReplacing:
					case SeaOverlayBehaviourMasking:
						selectOpacity = replace[j * lwidth + i];
						break;
						
					default:
						selectOpacity = options.overlayOpacity;
						break;
				}
#if MAIN_COMPILE
				if (options.useSelection) {
					point.x = i;
					point.y = j;
					if (IntPointInRect(point, selectRect)) {
						overlayOkay = YES;
						if (mask && !floating)
							selectOpacity = int_mult(selectOpacity, mask[(trueMaskOffset.y + point.y) * maskSize.width + (trueMaskOffset.x + point.x)], t1);
					}
				} else {
					overlayOkay = YES;
				}
#else
				overlayOkay = YES;
#endif
				
				// Don't do anything if there's no point
				if (selectOpacity == 0)
					overlayOkay = NO;
				
				// Apply the overlay if we get the okay
				if (overlayOkay) {
					if (selectedChannel == SeaSelectedChannelAll && !floating) {
						switch (options.overlayBehaviour) {
							case SeaOverlayBehaviourErasing:
								SeaEraseMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								
							case SeaOverlayBehaviourReplacing:
								SeaReplaceMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
								
							default:
								SeaSpecialMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
								break;
						}
					} else if (selectedChannel == SeaSelectedChannelPrimary || floating) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case SeaOverlayBehaviourReplacing:
									SeaReplacePrimaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
									break;
									
								default:
									SeaPrimaryMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity, YES);
									break;
							}
						}
					} else if (selectedChannel == SeaSelectedChannelAlpha) {
						if (selectOpacity > 0) {
							switch (options.overlayBehaviour) {							
								case SeaOverlayBehaviourReplacing:
									SeaReplaceAlphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
									break;
									
								default:
									SeaAlphaMerge(options.spp, tempSpace2, 0, overlay, srcLoc, selectOpacity);
									break;
							}
						}
					}
				}
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {
				// Copy pixel from destination in to temporary memory
				for (int k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				SeaSelectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				SeaNormalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			} else {
				// Then merge the pixel in temporary memory with the destination pixel
				SeaNormalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			}
		}
	}
}

- (void)compositeLayer:(SeaLayer *)layer withFloat:(SeaLayer *)floatingLayer andOptions:(CompositorOptions)options
{
	unsigned char *srcPtr, *floatPtr, *destPtr, *overlay, *replace;
	int lwidth = [layer width], lheight = [layer height], mode = [layer mode];
	int lfwidth = [floatingLayer width], lfheight = [floatingLayer height];

	int opacity = [layer opacity];
#if MAIN_COMPILE
	unsigned char *mask;
	int selectedChannel = [[document contents] selectedChannel];
#else
	int selectedChannel = [contents selectedChannel];
#endif
	int xoff = [layer xoff], yoff = [layer yoff], selectOpacity;
	int xfoff = [floatingLayer xoff], yfoff = [floatingLayer yoff];
	int startX, startY, endX, endY;
	int srcLoc, destLoc, floatLoc, tx, ty;
	unsigned char tempSpace[4], tempSpace2[4], tempSpace3[4];
	BOOL insertOverlay;
#if MAIN_COMPILE
	IntPoint maskOffset, trueMaskOffset;
	IntSize maskSize;
	IntRect selectRect;
#endif
	BOOL floating;
	
	// If the layer has an opacity of zero it does not need to be composited
	if (opacity == 0)
		return;
	
	// If the overlay has an opacity of zero it does not need to be inserted
	if (options.overlayOpacity == 0)
		insertOverlay = NO;
	else
		insertOverlay = options.insertOverlay;
	
#if MAIN_COMPILE
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([[document contents] width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([[document contents] height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	selectRect = [[document selection] localRect];
	srcPtr = [layer data];
	floatPtr = [floatingLayer data];
	destPtr = [[document whiteboard] data];
	overlay = [[document whiteboard] overlay];
	replace = [[document whiteboard] replace];
	mask = [[document selection] mask];
	maskOffset = [[document selection] maskOffset];
	trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	maskSize = [[document selection] maskSize];
	floating = [layer isFloating];
#else
	// Determine what is being copied
	startX = MAX(options.rect.origin.x - xoff, (xoff < 0) ? -xoff : 0);
	startY = MAX(options.rect.origin.y - yoff, (yoff < 0) ? -yoff : 0);
	endX = MIN([contents width] - xoff, lwidth);
	endX = MIN(endX, options.rect.origin.x + options.rect.size.width - xoff);
	endY = MIN([contents height] - yoff, lheight);
	endY = MIN(endY, options.rect.origin.y + options.rect.size.height - yoff);
	
	// Get some stuff we're going to use later
	//selectRect = [(SeaSelection *)[document selection] localRect];
	srcPtr = [layer data];
	floatPtr = [floatingLayer data];
	destPtr = [whiteboard data];
	overlay = [whiteboard overlay];
	replace = [whiteboard replace];
	//mask = [[document selection] mask];
	//maskOffset = [[document selection] maskOffset];
	//trueMaskOffset = IntMakePoint(maskOffset.x - selectRect.origin.x, maskOffset.y -  selectRect.origin.y);
	//maskSize = [[document selection] maskSize];
	floating = [layer isFloating];
#endif
	
	// Check what we are doing has a point
	if (endX - startX <= 0) return;
	if (endY - startY <= 0) return;
	
	// Go through each row
	for (int j = startY; j < endY; j++) {
		// Disolving requires us to play with the random number generator
		if (mode == XCF_DISSOLVE_MODE) {
			srandom(randomTable[(j + yoff) % 4096]);
			for (int k = 0; k < xoff; k++)
				random();
		}
		
		// Go through each column
		for (int i = startX; i < endX; i++) {
			// Determine the location in memory of the pixel we are copying from and to
			srcLoc = (j * lwidth + i) * options.spp;
			destLoc = ((j + yoff - options.destRect.origin.y) * options.destRect.size.width + (i + xoff - options.destRect.origin.x)) * options.spp;
			
			// Prepare for overlay application
			for (int k = 0; k < options.spp; k++)
				tempSpace2[k] = srcPtr[srcLoc + k];
				
			// Insert floating layer
			ty = yoff - yfoff + j;
			tx = xoff - xfoff + i;
			if (ty >= 0 && ty < lfheight) {
				if (tx >= 0 && tx < lfwidth) {
					floatLoc = (ty * lfwidth + tx) * options.spp;
					for (int k = 0; k < options.spp; k++)
						tempSpace3[k] = floatPtr[floatLoc + k];
					if (insertOverlay) {
						switch (options.overlayBehaviour) {
							case SeaOverlayBehaviourReplacing:
							case SeaOverlayBehaviourMasking:
								selectOpacity = replace[ty * lfwidth + tx];
								break;
								
							default:
								selectOpacity = options.overlayOpacity;
								break;
						}
						if (selectOpacity > 0) {
							SeaPrimaryMerge(options.spp, tempSpace3, 0, overlay, floatLoc, selectOpacity, YES);
						}
					}
					if (selectedChannel == SeaSelectedChannelAll) {
						SeaNormalMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					} else if (selectedChannel == SeaSelectedChannelPrimary) {
						SeaPrimaryMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255, YES);
					} else if (selectedChannel == SeaSelectedChannelAlpha) {
						SeaAlphaMerge(options.spp, tempSpace2, 0, tempSpace3, 0, 255);
					}
				}
			}
			
			// If the layer is going to use a compositing effect...
			if (normal == NO && mode != XCF_NORMAL_MODE && options.forceNormal == NO) {
				// Copy pixel from destination in to temporary memory
				for (int k = 0; k < options.spp; k++)
					tempSpace[k] = destPtr[destLoc + k];
				
				// Apply the appropriate effect using the source pixel
				SeaSelectMerge(mode, options.spp, tempSpace, 0, tempSpace2, 0);
				
				// Then merge the pixel in temporary memory with the destination pixel
				SeaNormalMerge(options.spp, destPtr, destLoc, tempSpace, 0, opacity);
			} else {
				// Then merge the pixel in temporary memory with the destination pixel
				SeaNormalMerge(options.spp, destPtr, destLoc, tempSpace2, 0, opacity);
			
			}
			
		}
	}
}

@end
