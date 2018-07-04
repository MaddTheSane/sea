#include <math.h>
#include <tgmath.h>
#import "SeaPrintView.h"
#import "SeaView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "UtilitiesManager.h"
#import "TransparentUtility.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaLayer.h"
#import "ToolboxUtility.h"
#import "SeaWhiteboard.h"
#import "SeaTools.h"
#import "PositionTool.h"
#import "PencilTool.h"
#import "BrushTool.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
#import "SeaController.h"

@implementation SeaPrintView

- (instancetype)initWithDocument:(SeaDocument*)doc
{	
	NSRect frame;
		
	// Remember the document this view is displaying

	// Determine the frame at 100% 72-dpi
	frame = NSMakeRect(0, 0, [(SeaContent*)[doc contents] width] * (72.0 / (CGFloat)[[doc contents] xres]), [[doc contents] height] * (72.0 / (CGFloat)[[document contents] yres]));

	// Initialize superclass
	if (!(self = [super initWithFrame:frame]))
		return NULL;
	
	document = doc;
	
    return self;
}


- (void)drawRect:(NSRect)rect
{
	NSRect srcRect = rect, destRect = rect;
	NSImage *image = NULL;
	int xres = [[document contents] xres], yres = [[document contents] yres];

	// Get the correct image for displaying
	image = [[document whiteboard] printableImage];
	
	// Set the background color
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRect:destRect] fill];
	
	// For non 72 dpi resolutions we must scale here
	if (xres != 72) {
		srcRect.origin.x *= ((CGFloat)xres / 72.0);
		srcRect.size.width *= ((CGFloat)xres / 72.0);
	}
	if (yres != 72) {
		srcRect.origin.y *= ((CGFloat)yres / 72.0);
		srcRect.size.height *= ((CGFloat)yres / 72.0);
	}
	
	// Set interpolation (image smoothing) appropriately
	if ([[SeaController seaPrefs] smartInterpolation]) {
		if (srcRect.size.width > destRect.size.width)
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		else
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	} else {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	}
	
	// Draw the image to screen
	[image drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (BOOL)knowsPageRange:(NSRangePointer)range
{
	NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
	NSRect bounds;
	NSRect paper;
	float scale;
	
	// Work out the image's bounds
	bounds = NSMakeRect(0, 0, [(SeaContent *)[document contents] width] * (72.0 / (CGFloat)[[document contents] xres]), [(SeaContent *)[document contents] height] * (72.0 / (CGFloat)[[document contents] yres]));
	
	// Work out the paper's bounding rectangle
	paper.size = [pi paperSize];
	paper.size.height -= [pi topMargin] + [pi bottomMargin];
	paper.size.width -= [pi leftMargin] + [pi rightMargin];
	scale = [[pi dictionary][NSPrintScalingFactor] floatValue];
	paper.size.height /= scale;
	paper.size.width /= scale;
	
	if (bounds.size.width < paper.size.width && bounds.size.height < paper.size.height) {
		// Handle one page documents
		range->location = 1;
		range->length = 1;
		[pi setHorizontallyCentered:YES];
		[pi setVerticallyCentered:YES];
	} else {
		// Otherwise do tiling
		range->location = 1;
		range->length = ceil((float)bounds.size.width / (float)paper.size.width) * ceil((float)bounds.size.height / (float)paper.size.height);
		[pi setHorizontallyCentered:NO];
		[pi setVerticallyCentered:NO];
	}
	
	return YES;
}

__unused static inline float mod(float a, float b) __attribute__((__overloadable__))
{
	float result;
	
	result = fabsf(a);
	while (result - b > 0.0) {
		result -= b;
	}
	
	return result;
}

__unused static inline double mod(double a, double b) __attribute__((__overloadable__))
{
	double result;
	
	result = fabs(a);
	while (result - b > 0.0) {
		result -= b;
	}
	
	return result;
}


- (NSRect)rectForPage:(int)page
{
	NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
	NSRect bounds, paper, result;
	CGFloat scale;
	int horizPages, vertPages;
	
	// Work out the image's bounds
	bounds = NSMakeRect(0, 0, [(SeaContent*)[document contents] width] * (72.0 / (float)[[document contents] xres]), [[document contents] height] * (72.0 / (CGFloat)[[document contents] yres]));
	
	// Work out the paper's bounding rectangle
	paper.size = [pi paperSize];
	paper.size.height -= [pi topMargin] + [pi bottomMargin];
	paper.size.width -= [pi leftMargin] + [pi rightMargin];
	scale = [[pi dictionary][NSPrintScalingFactor] doubleValue];
	paper.size.height /= scale;
	paper.size.width /= scale;
	
	if (bounds.size.width < paper.size.width && bounds.size.height < paper.size.height) {
	
		// Handle one page documents
		return bounds;
		
	}
	else {
	
		// Correct page (we work from page zero)
		page--;
	
		// Otherwise do tiling
		horizPages = ceil(bounds.size.width / paper.size.width);
		vertPages = ceil(bounds.size.height / paper.size.height);
		
		// Work out origin
		result.origin.x = (page % horizPages) * paper.size.width;
		result.origin.y = (page / horizPages) * paper.size.height;
		
		// Work out width
		if (page % horizPages == horizPages - 1)
			result.size.width = mod(bounds.size.width, paper.size.width);
		else
			result.size.width = paper.size.width;
		
		// Work out height
		if (page / horizPages == vertPages - 1)
			result.size.height = mod(bounds.size.height, paper.size.height);
		else
			result.size.height = paper.size.height;
		
	}
	
	return result;
}


- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

@end
