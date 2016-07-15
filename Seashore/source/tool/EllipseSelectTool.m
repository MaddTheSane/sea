#import "EllipseSelectTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "EllipseSelectOptions.h"
#import "RectSelectOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "AspectRatio.h"

@implementation EllipseSelectTool

- (SeaToolsDefines)toolId
{
	return kEllipseSelectTool;
}


- (IntRect) selectionRect
{
	return selectionRect;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDownAt:where withEvent:event];

	// Otherwise do the following...
	if (![super isMovingOrScaling]) {
		SeaAspectType aspectType = [options aspectType];
		NSSize ratio;
		double xres, yres;
		int modifier;
		
		// Get mode
		modifier = [options modifier];
		if(modifier == kShiftModifier){
			oneToOne = YES;
		}else{
			oneToOne = NO;
		}
		
		
		// Clear the active selection and start the selection
		if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
			[[document selection] clearSelection];

		// Record the start point
		startPoint = where;

		selectionRect.origin = where;
		
		// If we have a fixed size selection
		if (aspectType >= kExactPixelAspectType) {
		
			// Determine it
			ratio = [options ratio];
			xres = [[document contents] xres];
			yres = [[document contents] yres];
			switch (aspectType) {
				case kExactPixelAspectType:
					selectionRect.size.width = ratio.width;
					selectionRect.size.height = ratio.height;
					break;
					
				case kExactInchAspectType:
					selectionRect.size.width = ratio.width * xres;
					selectionRect.size.height = ratio.height * yres;
					break;
					
				case kExactMillimeterAspectType:
					selectionRect.size.width = ratio.width * xres * 0.03937;
					selectionRect.size.height = ratio.height * yres * 0.03937;
					break;
					
				default:
					break;
			}
		}
		[[document helpers] selectionChanged];	
		intermediate = YES;
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDraggedTo:where withEvent:event];
	
	// Check we have a valid start point
	if (intermediate && ![super isMovingOrScaling]) {
		SeaAspectType aspectType = [options aspectType];
		NSSize ratio;
	
		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || oneToOne) {
		
			// Determine the width of the selection rectangle
			if (startPoint.x < where.x) {
				selectionRect.size.width = where.x - startPoint.x;
				selectionRect.origin.x = startPoint.x;
			} else {
				selectionRect.origin.x = where.x;
				selectionRect.size.width = startPoint.x - where.x;
			}
			
			// Determine the height of the selection rectangle
			if (aspectType == kRatioAspectType || oneToOne) {
				if (oneToOne)
					ratio = NSMakeSize(1, 1);
				else
					ratio = [options ratio];
				if (startPoint.y < where.y) {
					selectionRect.size.height = selectionRect.size.width * ratio.height;
					selectionRect.origin.y = startPoint.y;
				}
				else {
					selectionRect.size.height = selectionRect.size.width * ratio.height;
					selectionRect.origin.y = startPoint.y - selectionRect.size.height;
				}
			}
			else {
				if (selectionRect.origin.y < where.y) {
					selectionRect.size.height = where.y - startPoint.y;
					selectionRect.origin.y = startPoint.y;
				}
				else {
					selectionRect.origin.y = where.y;
					selectionRect.size.height = startPoint.y - where.y;
				}
			}

		} else {

			// Just change the origin
			selectionRect.origin.x = where.x;
			selectionRect.origin.y = where.y;

		}
		[[document helpers] selectionChanged];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseUpAt:where withEvent:event];
	if (intermediate && ![super isMovingOrScaling]) {
		[[document selection] selectEllipse:selectionRect mode:[options selectionMode]];
		selectionRect = IntMakeRect(0,0,0,0);
		intermediate = NO;
	}
	
	scalingDir = kNoDir;
	translating = NO;
}

- (void)cancelSelection
{
	selectionRect = IntMakeRect(0,0,0,0);
	[super cancelSelection];
}
@end