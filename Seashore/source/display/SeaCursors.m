#import "SeaCursors.h"
#import "SeaTools.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaView.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "SeaLayer.h"
#import "SeaContent.h"
#import "OptionsUtility.h"
#import "BrushOptions.h"
#import "PencilOptions.h"
#import "PositionTool.h"
#import "CropTool.h"
#import "PositionOptions.h"

@implementation SeaCursors
@synthesize closeRect;

- (instancetype)initWithDocument:(SeaDocument*)newDocument andView:(id)newView
{
	if (self = [super init]) {
	document = newDocument;
	view = newView;
	/* Set-up the cursors */
	// Tool Specific Cursors
	crosspointCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/crosspoint"] hotSpot:NSMakePoint(7, 7)];
	[crosspointCursor setOnMouseEntered:YES];
	wandCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/wand"] hotSpot:NSMakePoint(2, 2)];
	[wandCursor setOnMouseEntered:YES];
	zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/zoom"] hotSpot:NSMakePoint(5, 6)];
	[zoomCursor setOnMouseEntered:YES];
	pencilCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/pencil"] hotSpot:NSMakePoint(3, 15)];
	[pencilCursor setOnMouseEntered:YES];
	brushCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/brush"] hotSpot:NSMakePoint(1, 14)];
	[brushCursor setOnMouseEntered:YES];
	bucketCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/bucket"] hotSpot:NSMakePoint(14, 14)];
	[bucketCursor setOnMouseEntered:YES];
	eyedropCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/eyedrop"] hotSpot:NSMakePoint(1, 14)];
	[eyedropCursor setOnMouseEntered:YES];
	moveCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/move"] hotSpot:NSMakePoint(7, 7)];
	[moveCursor setOnMouseEntered:YES];
	eraserCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/eraser"] hotSpot:NSMakePoint(2, 12)];
	[eraserCursor setOnMouseEntered:YES];
	smudgeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/smudge"] hotSpot:NSMakePoint(1, 15)];
	[smudgeCursor setOnMouseEntered:YES];
	effectCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/effect"] hotSpot:NSMakePoint(1, 1)];
	[smudgeCursor setOnMouseEntered:YES];
	noopCursor = [NSCursor operationNotAllowedCursor];
	[noopCursor setOnMouseEntered:YES];
	
	// Additional Cursors
	addCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/crosspoint-add"] hotSpot:NSMakePoint(7, 7)];
	[addCursor setOnMouseEntered:YES];
	subtractCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/crosspoint-subtract"] hotSpot:NSMakePoint(7, 7)];
	[subtractCursor setOnMouseEntered:YES];
	closeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/crosspoint-close"] hotSpot:NSMakePoint(7, 7)];
	[closeCursor setOnMouseEntered:YES];
	resizeCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/resize"] hotSpot:NSMakePoint(7, 7)];
	[resizeCursor setOnMouseEntered:YES];
	rotateCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/rotate"] hotSpot:NSMakePoint(7, 7)];
	[rotateCursor setOnMouseEntered:YES];
	anchorCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/anchor"] hotSpot:NSMakePoint(7, 7)];
	[anchorCursor setOnMouseEntered:YES];
	
	// View Generic Cursors
	handCursor = [NSCursor openHandCursor];
	[handCursor setOnMouseEntered:YES];
	grabCursor = [NSCursor closedHandCursor];
	[grabCursor setOnMouseEntered:YES];
	lrCursor = [NSCursor resizeLeftRightCursor];
	[lrCursor setOnMouseEntered:YES];
	udCursor = [NSCursor resizeUpDownCursor];
	[udCursor setOnMouseEntered:YES];
	urdlCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/resize-ne-sw"] hotSpot:NSMakePoint(7, 7)];
	[urdlCursor setOnMouseEntered:YES];
	uldrCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursors/resize-nw-se"] hotSpot:NSMakePoint(7, 7)];
	[uldrCursor setOnMouseEntered:YES];
	
	handleCursors[0] = uldrCursor;
	handleCursors[1] = udCursor;
	handleCursors[2] = urdlCursor;
	handleCursors[3] = lrCursor;
	handleCursors[4] = uldrCursor;
	handleCursors[5] = udCursor;
	handleCursors[6] = urdlCursor;
	handleCursors[7] = lrCursor;
	
	scrollingMode = NO;
	scrollingMouseDown = NO;
	}
	
	return self;
}

- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor
{
	NSScrollView *scrollView = [view enclosingScrollView];
	
	// Convert to the scrollview's origin
	rect.origin = [scrollView convertPoint: rect.origin fromView: view];
	
	// Clip to the centering clipview
	NSRect clippedRect = NSIntersectionRect([[view superview] frame], rect);

	// Convert the point back to the seaview
	clippedRect.origin = [view convertPoint: clippedRect.origin fromView: scrollView];
	[view addCursorRect:clippedRect cursor:cursor];
}

- (void)resetCursorRects
{
	if (scrollingMode) {
		if (scrollingMouseDown)
			[self addCursorRect:[view frame] cursor:grabCursor];
		else
			[self addCursorRect:[view frame] cursor:handCursor];
		return;
	}
	
	SeaToolsDefines tool = [[[SeaController utilitiesManager] toolboxUtilityFor:document] tool];
	SeaLayer *activeLayer = [[document contents] activeLayer];
	CGFloat xScale = [[document contents] xscale];
	CGFloat yScale = [[document contents] yscale];
	IntRect operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
	NSRect operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect));

	if (tool >= SeaToolsFirstSelection && tool <= SeaToolsLastSelection) {
		// Find out what the selection mode is
		SeaSelectMode selectionMode = [(AbstractSelectOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] selectionMode];
		
		if (selectionMode == SeaSelectAdd) {
			[self addCursorRect:operableRect cursor:addCursor];
		} else if (selectionMode == SeaSelectSubtract) {
			[self addCursorRect:operableRect cursor:subtractCursor];
		} else if(selectionMode != SeaSelectDefault) {
			[self addCursorRect:operableRect cursor:crosspointCursor];
		} else {
			[self addCursorRect:operableRect cursor:crosspointCursor];
			
			// Now we need the handles and the hand
			if (document.selection.active) {
				NSRect selectionRect = IntRectMakeNSRect([[document selection] globalRect]);
				selectionRect = NSMakeRect(selectionRect.origin.x * xScale, selectionRect.origin.y * yScale, selectionRect.size.width * xScale, selectionRect.size.height * yScale);

				[self addCursorRect:NSConstrainRect(selectionRect,[view frame]) cursor:handCursor];
				for (int i = 0; i < 8; i++) {
					[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
				}
				
			}
		}
		
		if (tool == SeaToolsPolygonLasso && closeRect.size.width > 0 && closeRect.size.height > 0) {
			[self addCursorRect:closeRect cursor: closeCursor];
		}
	} else if(tool == SeaToolsCrop) {
		[self addCursorRect:[view frame] cursor:crosspointCursor];
		
		IntRect origRect = [(CropTool *)[[document tools] currentTool] cropRect];
		NSRect cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
		
		if (cropRect.size.width != 0 && cropRect.size.height != 0) {
			[self addCursorRect:NSConstrainRect(cropRect,[view frame]) cursor:handCursor];
			for (int i = 0; i < 8; i++) {
				[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
			}
		}
	} else if (tool == SeaToolsPosition) {
		NSRect cropRect;
		IntRect origRect;

		[self addCursorRect:[view frame] cursor:moveCursor];
		
		origRect =IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect);
		cropRect = NSMakeRect(origRect.origin.x * xScale, origRect.origin.y * yScale, origRect.size.width * xScale, origRect.size.height * yScale);
		
		if (cropRect.size.width != 0 && cropRect.size.height != 0) {
			[self addCursorRect:NSConstrainRect(cropRect,[view frame]) cursor:handCursor];
			for (int i = 0; i < 8; i++) {
				[self addCursorRect:handleRects[i] cursor:handleCursors[i]];
			}
		}
	} else {
		// If there is currently a selection, then users can operate in there only
		if(document.selection.active){
			operableIntRect = [[document selection] globalRect];
			operableIntRect = IntMakeRect(operableIntRect.origin.x * xScale, operableIntRect.origin.y * yScale, operableIntRect.size.width * xScale, operableIntRect.size.height * yScale);
			operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([view frame]), operableIntRect));
		}
		
		switch (tool) {
			case SeaToolsZoom:
				[self addCursorRect:[view frame] cursor:zoomCursor];
				break;
			case SeaToolsPencil:
				[self addCursorRect:operableRect cursor:pencilCursor];
				break;
			case SeaToolsBrush:
				[self addCursorRect:operableRect cursor:brushCursor];
				break;
			case SeaToolsBucket:
				[self addCursorRect:operableRect cursor:bucketCursor];
				break;
			case SeaToolsText:
				[self addCursorRect:operableRect cursor:[NSCursor IBeamCursor]];
				break;
			case SeaToolsEyedrop:
				[self addCursorRect:[view frame] cursor:eyedropCursor];
				break;
			case SeaToolsEraser:
				[self addCursorRect:operableRect cursor:eraserCursor];
				break;
			case SeaToolsGradient:
				[self addCursorRect:[view frame] cursor:crosspointCursor];
				break;
			case SeaToolsSmudge:
				[self addCursorRect:[view frame] cursor:smudgeCursor];
				break;
			case SeaToolsClone:
				[self addCursorRect:[view frame] cursor:brushCursor];
				break;
			case SeaToolsEffect:
				[self addCursorRect:[view frame] cursor:effectCursor];
				break;
			default:
				[self addCursorRect:operableRect cursor:NULL];
				break;
		}
		
	}

	if (tool == SeaToolsBrush && [(BrushOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] brushIsErasing]) {
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:brushCursor];
		[self addCursorRect:operableRect cursor:eraserCursor];
	} else if (tool == SeaToolsPencil && [(PencilOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool] pencilIsErasing]) {
		// Do we need this?
		//[view removeCursorRect:operableRect cursor:pencilCursor];
		[self addCursorRect:operableRect cursor:eraserCursor];
	}/*else if (tool == kPositionTool){
		PositionOptions *options = (PositionOptions *)[[[SeaController utilitiesManager] optionsUtilityFor:document] getOptions:tool];
		if([options toolFunction] == kScalingLayer){
			[self addCursorRect:[view frame] cursor:resizeCursor];
		}else if([options toolFunction] == kRotatingLayer){
			[self addCursorRect:[view frame] cursor:rotateCursor];
		}else if([options toolFunction] == kMovingLayer){
			[self addCursorRect:[view frame] cursor:moveCursor];
		}
	}*/
	
	
	// Some tools can operate outside of the selection rectangle
	if (tool != SeaToolsZoom && tool != SeaToolsEyedrop && tool != SeaToolsGradient && tool != SeaToolsSmudge && tool != SeaToolsClone && tool != SeaToolsCrop && tool != SeaToolsEffect && tool != SeaToolsPosition) {
		// Now we need the noop section		
		if (operableRect.origin.x > 0) {
			NSRect leftRect = NSMakeRect(0,0,operableRect.origin.x,[view frame].size.height);
			[self addCursorRect:leftRect cursor:noopCursor];
		}
		CGFloat rightX = operableRect.origin.x + operableRect.size.width;
		if (rightX < [view frame].size.width) {
			NSRect rightRect = NSMakeRect(rightX, 0, [view frame].size.width - rightX, [view frame].size.height);
			[self addCursorRect:rightRect cursor:noopCursor];
		}
		if (operableRect.origin.y > 0) {
			NSRect bottomRect = NSMakeRect(0, 0, [view frame].size.width, operableRect.origin.y);
			[self addCursorRect:bottomRect cursor:noopCursor];
		}
		CGFloat topY = operableRect.origin.y + operableRect.size.height;
		if (topY < [view frame].size.height) {
			NSRect topRect = NSMakeRect(0, topY, [view frame].size.width, [view frame].size.height - topY);
			[self addCursorRect:topRect cursor:noopCursor];
		}
	}
}

- (NSRect *)handleRectsPointer
{
	return handleRects;
}

- (void)setScrollingMode:(BOOL)inMode mouseDown:(BOOL)mouseDown
{
	scrollingMode = inMode;
	scrollingMouseDown = mouseDown;	
}

@end
