#import "PositionTool.h"
#import "PositionOptions.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaSelection.h"
#import "SeaLayerUndo.h"
#import "SeaOperations.h"
#import "SeaRotation.h"
#import "SeaScale.h"


@implementation PositionTool
@synthesize scale;
@synthesize rotation;
@synthesize rotationDefined;

- (SeaToolsDefines)toolId
{
	return kPositionTool;
}

- (instancetype)init
{
	if(![super init])
		return nil;
	
	scale = -1;
	rotation = 0.0;
	rotationDefined = NO;
	
	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaContent *contents = [document contents];
	SeaLayer *activeLayer = [contents activeLayer];
	IntPoint oldOffsets;
	int whichLayer;
	int function = kMovingLayer;
	
	// Determine the function
	if (activeLayer.floating && [options canAnchor] && (where.x < 0 || where.y < 0 || where.x >= [activeLayer width] || where.y >= [activeLayer height])){
		function = kAnchoringLayer;
	}else{
		function = [options toolFunction];
	}

	// Record the inital point for dragging
	initialPoint = where;

	// Vary behaviour based on function
	switch (function) {
		case kMovingLayer:
			
			// Determine the absolute where
			where.x += [activeLayer xoff]; where.y += [activeLayer yoff];
			activeLayer = [contents activeLayer];
			
			// Record the inital point for dragging
			initialPoint.x = where.x - [activeLayer xoff];
			initialPoint.y = where.y - [activeLayer yoff];
			
			// If the active layer is linked we have to move all associated layers
			if (activeLayer.linked) {
			
				// Go through all linked layers allowing a satisfactory undo
				for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
					if ([contents layerAtIndex:whichLayer].linked) {
						oldOffsets.x = [[contents layerAtIndex:whichLayer] xoff]; oldOffsets.y = [[contents layerAtIndex:whichLayer] yoff];
						[[[document undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:whichLayer];			
					}
				}
				
			}
			else {
				
				// Allow the undo
				oldOffsets.x = [activeLayer xoff]; oldOffsets.y = [activeLayer yoff];
				[[[document undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:[contents activeLayerIndex]];
			
			}
			
		break;
		case kRotatingLayer:
		
			// Start rotating layer
			rotation = 0.0;
			rotationDefined = YES;
			[[document docView] setNeedsDisplay:YES]; 
			
		break;
		case kScalingLayer:
		
			// Start scaling layer
			scale = 1.0;
			[[document docView] setNeedsDisplay:YES];
			
		break;
		case kAnchoringLayer:
		
			// Anchor the layer
			[contents anchorSelection];
			
		break;
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaContent *contents = [document contents];
	SeaLayer *activeLayer = [contents activeLayer];
	int xoff, yoff, whichLayer;
	int deltax = where.x - initialPoint.x, deltay = where.y - initialPoint.y;
	IntPoint oldOffsets = {0};
	NSPoint activeCenter = NSMakePoint([activeLayer xoff] + [(SeaLayer *)activeLayer width] / 2, [activeLayer yoff] + [(SeaLayer *)activeLayer height] / 2);
	CGFloat original, current;
	
	// Vary behaviour based on function
	switch ([options  toolFunction]) {
		case SeaPositionOptionMoving:
			
			// If the active layer is linked we have to move all associated layers
			if (activeLayer.linked) {
			
				// Move all of the linked layers
				for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
					if ([contents layerAtIndex:whichLayer].linked) {
						xoff = [[contents layerAtIndex:whichLayer] xoff]; yoff = [[contents layerAtIndex:whichLayer] yoff];
						[[contents layerAtIndex:whichLayer] setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
					}
				}
				[[document helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
				
			}
			else {
			
				// Move the active layer
				xoff = [activeLayer xoff]; yoff = [activeLayer yoff];
				oldOffsets = IntMakePoint(xoff, yoff);
				[activeLayer setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
				[[document helpers] layerOffsetsChanged:kActiveLayer from:oldOffsets];
				
			}
			
		break;
		case SeaPositionOptionRotating:
		
			// Continue rotating layer
			original = atan((initialPoint.y - activeCenter.y) / (initialPoint.x - activeCenter.x));
			current = atan((where.y - activeCenter.y) / (where.x - activeCenter.x));
			rotation = current - original;
			
		
		break;
		case SeaPositionOptionScaling:
	
			// Continue scaling layer
			original = sqrt(sqr(initialPoint.x - activeCenter.x) + sqr(initialPoint.y - activeCenter.y));
			current = sqrt(sqr(where.x - activeCenter.x) + sqr(where.y - activeCenter.y));
			scale = current / original;
		
		break;
			
		case SeaPositionOptionAnchoring:
			break;
	}
	[[document docView] setNeedsDisplay:YES];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaLayer *layer;
	int deltax;
	int newWidth, newHeight;
	
	// Determine the delta
	deltax = where.x - initialPoint.x;
	
	// Vary behaviour based on function
	switch ([options toolFunction]) {
		case kRotatingLayer:
			// Finish rotating layer
			[[seaOperations seaRotation] rotate:rotation * 180.0 / 3.1415 withTrim:YES];
			break;
			
		case kScalingLayer:
			// Finish scaling layer
			layer = [[document contents] activeLayer];
			newWidth = scale *  [layer width];
			newHeight = scale * [layer height];
			[[seaOperations seaScale] scaleToWidth:newWidth height:newHeight interpolation:GIMP_INTERPOLATION_CUBIC index:kActiveLayer];
			break;
			
		default:
			break;
	}
	
	// Cancel the previewing
	scale = -1;
	rotationDefined = NO;
}

- (void)undoToOrigin:(IntPoint)origin forLayer:(NSInteger)index
{
	IntPoint oldOffsets;
	id layer = [[document contents] layerAtIndex:index];
	
	oldOffsets.x = [layer xoff]; oldOffsets.y = [layer yoff];
	[[[document undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:index];
	[layer setOffsets:origin];
	[[document helpers] layerOffsetsChanged:index from:oldOffsets];
}

@end
