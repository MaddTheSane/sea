#import "BrushView.h"
#import "BrushUtility.h"
#import "SeaBrush.h"

@implementation BrushView

- (instancetype)initWithMaster:(BrushUtility*)sender
{
	if (self =[super init]) {
		master = sender;
		[self update];
	}
	return self;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:NULL];
	NSInteger elemNo;
	
	// Make the change and call for an update
	elemNo = ((NSInteger)clickPoint.y / kBrushPreviewSize) * kBrushesPerRow + (NSInteger)clickPoint.x / kBrushPreviewSize;
	if (elemNo < [[master brushes] count]) {
		[master setActiveBrushIndex:elemNo];
		[self setNeedsDisplay:YES];
	}
}

- (void)drawRect:(NSRect)rect
{
	NSArray *brushes = [master brushes];
	NSInteger brushCount =  [brushes count];
	NSInteger activeBrushIndex = [master activeBrushIndex];
	
	// Draw background
	[[NSColor lightGrayColor] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
		
	// Draw each elements
	for (NSInteger i = rect.origin.x / kBrushPreviewSize; i <= (rect.origin.x + rect.size.width) / kBrushPreviewSize; i++) {
		for (NSInteger j = rect.origin.y / kBrushPreviewSize; j <= (rect.origin.y + rect.size.height) / kBrushPreviewSize; j++) {
		
			// Determine the element number and rectange
			NSInteger elemNo = j * kBrushesPerRow + i;
			NSRect elemRect = NSMakeRect(i * kBrushPreviewSize, j * kBrushPreviewSize, kBrushPreviewSize, kBrushPreviewSize);
			
			// Continue if we are in range
			if (elemNo < brushCount) {
				// Draw the brush background and frame
				[[NSColor whiteColor] set];
				[[NSBezierPath bezierPathWithRect:elemRect] fill];
				if (elemNo != activeBrushIndex) {
					[[NSColor grayColor] set];
					[NSBezierPath setDefaultLineWidth:1];
					[[NSBezierPath bezierPathWithRect:elemRect] stroke];
				} else {
					[[NSColor blackColor] set];
					[NSBezierPath setDefaultLineWidth:2];
					NSRect tempRect = elemRect;
					tempRect.origin.x++; tempRect.origin.y++; tempRect.size.width -= 2; tempRect.size.height -= 2;
					[[NSBezierPath bezierPathWithRect:tempRect] stroke];
				}
				
				// Draw the thumbnail
				NSImage *thumbnail = [brushes[elemNo] thumbnail];
				[thumbnail drawAtPoint:NSMakePoint(i * kBrushPreviewSize + kBrushPreviewSize / 2 - [thumbnail size].width / 2, j * kBrushPreviewSize + kBrushPreviewSize / 2 + [thumbnail size].height / 2) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				
				// Draw the pixel tag if needed
				NSString *pixelTag = [brushes[elemNo] pixelTag];
				if (pixelTag) {
					NSFont *font = [NSFont systemFontOfSize:9.0];
					NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]};
					IntSize fontSize = NSSizeMakeIntSize([pixelTag sizeWithAttributes:attributes]);
					[pixelTag drawAtPoint:NSMakePoint(elemRect.origin.x + elemRect.size.width / 2 - fontSize.width / 2, elemRect.origin.y + elemRect.size.height / 2 - fontSize.height / 2) withAttributes:attributes];
				}
			}
		}
	}
}

- (void)update
{
	NSArray *brushes = [master brushes];
	NSInteger brushCount =  [brushes count];
	
	[self setFrameSize:NSMakeSize(kBrushPreviewSize * kBrushesPerRow + 1, ((brushCount % kBrushesPerRow == 0) ? (brushCount / kBrushesPerRow) : (brushCount / kBrushesPerRow + 1)) * kBrushPreviewSize)];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
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
