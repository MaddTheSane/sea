#import "BucketTool.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "Bucket.h"
#import "OptionsUtility.h"
#import "BucketOptions.h"
#import "StandardMerge.h"
#import "SeaTexture.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "SeaView.h"

@implementation BucketTool
@synthesize start = startNSPoint;
@synthesize current = currentNSPoint;

- (SeaToolsDefines)toolId
{
	return kBucketTool;
}

- (instancetype)init
{
	self = [super init];
	if(self){
		isPreviewing = NO;
	}
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	startPoint = where;
	
	startNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	if ([options modifier] == AbstractModifierShift) {
		isPreviewing = YES;
	}
	
	intermediate = YES;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	currentNSPoint = [[document docView] convertPoint:[event locationInWindow] fromView:NULL];
	
	BOOL optionDown = [options modifier] == AbstractModifierAlt;

	SeaLayer *layer = [[document contents] activeLayer];
	int width = [layer width], height = [layer height];
	
	[[document whiteboard] clearOverlay];
	[[document helpers] overlayChanged:rect inThread:NO];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	} else if (isPreviewing) {
		[self fillAtPoint:where useTolerance:!optionDown delay:YES];
	}
	
	[[document docView] setNeedsDisplay: YES];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaLayer *layer = [[document contents] activeLayer];
	int width = [layer width], height = [layer height];
	BOOL optionDown = [options modifier] == AbstractModifierAlt;
	
	[[document whiteboard] clearOverlay];
	[[document helpers] overlayChanged:rect inThread:NO];

	if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
		rect.size.width = rect.size.height = 0;
	} else if(!isPreviewing || [options modifier] != AbstractModifierShift) {
		[self fillAtPoint:where useTolerance:!optionDown delay:NO];
	}
	isPreviewing = NO;
	intermediate = NO;
}

- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance delay:(BOOL)delay
{
	SeaLayer *layer = [[document contents] activeLayer];
	SeaTexture *activeTexture = [[[SeaController utilitiesManager] textureUtilityFor:document] activeTexture];
	int tolerance, width = [layer width], height = [layer height], spp = [[document contents] spp];
	int textureWidth = [activeTexture width], textureHeight = [activeTexture height];
	unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];
	unsigned char *texture = [activeTexture texture:(spp == 4)];
	unsigned char basePixel[4];
	NSColor *color = [[document contents] foreground];
	int k, channel;
	
	// Set the overlay to fully opaque
	[[document whiteboard] setOverlayOpacity:255];
	
	// Determine the bucket's colour
	if ([options useTextures]) {
		for (k = 0; k < spp - 1; k++)
			basePixel[k] = 0;
		basePixel[spp - 1] = [[[SeaController utilitiesManager] textureUtilityFor:document] opacity];
	}
	else {
		if (spp == 4) {
			basePixel[0] = (unsigned char)([color redComponent] * 255.0);
			basePixel[1] = (unsigned char)([color greenComponent] * 255.0);
			basePixel[2] = (unsigned char)([color blueComponent] * 255.0);
			basePixel[3] = (unsigned char)([color alphaComponent] * 255.0);
		}
		else {
			basePixel[0] = (unsigned char)([color whiteComponent] * 255.0);
			basePixel[1] = (unsigned char)([color alphaComponent] * 255.0);
		}
	}
		
	
	int intervals = [options numIntervals];
	
	IntPoint* seeds = malloc(sizeof(IntPoint) * (intervals + 1));
	
	int seedIndex;
	int xDelta = point.x - startPoint.x;
	int yDelta = point.y - startPoint.y;
	for(seedIndex = 0; seedIndex <= intervals; seedIndex++){
		int x = startPoint.x + (int)ceil(xDelta * ((float)seedIndex / intervals));
		int y = startPoint.y + (int)ceil(yDelta * ((float)seedIndex / intervals));
		seeds[seedIndex] = IntMakePoint(x, y);				
	}

	
	// Fill everything
	if (useTolerance) {
		tolerance = [(BucketOptions*)options tolerance];
	} else {
		tolerance = 255;
	}
	
	if (layer.floating) {
		channel = SeaSelectedChannelPrimary;
	} else {
		channel = [[document contents] selectedChannel];
	}
	
	if (document.selection.active) {
		rect = SeaBucketFill(spp, [[document selection] localRect], overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
	} else {
		rect = SeaBucketFill(spp, IntMakeRect(0, 0, width, height), overlay, data, width, height, seeds, intervals, basePixel, tolerance, channel);
	}
	
	if ([options useTextures] && IntContainsRect(IntMakeRect(0, 0, width, height), rect)) {
		if (document.selection.active) {
			SeaTextureFill(spp, rect, overlay, width, height, texture, textureWidth, textureHeight);
		} else {
			SeaTextureFill(spp, rect, overlay, width, height, texture, textureWidth, textureHeight);
		}
	}
	
	// Do the update
	if (delay)
		[[document helpers] overlayChanged:rect inThread:NO];
	else
		[(SeaHelpers *)[document helpers] applyOverlay];
}

@end
