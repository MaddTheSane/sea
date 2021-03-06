#import "AbstractSelectTool.h"

#import "SeaDocument.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "AbstractOptions.h"
#import "SeaContent.h"

@implementation AbstractSelectTool

- (void)mouseDownAt:(IntPoint)localPoint withEvent:(NSEvent *)event
{	
	if (document.selection.active) {
		/* incidentally, we should only be translating when the mode is default
		 However, we don't know how to pass that logic in yet
		 here it is:
		 [(AbstractSelectOptions *)options selectionMode] == kDefaultMode
		 */
		
		[self mouseDownAt: localPoint
				  forRect: [[document selection] globalRect]
				  andMask: [(SeaSelection*)[document selection] mask]];
		
		// Also, we universally float the selection if alt is down
		if(![self isMovingOrScaling] && [options modifier] == AbstractModifierAlt) {
			[[document contents] makeSelectionFloat:NO];
		}
	}	
}

- (void)mouseDraggedTo:(IntPoint)localPoint withEvent:(NSEvent *)event
{
	if (document.selection.active) {
		IntRect newRect = [self mouseDraggedTo: localPoint
									   forRect: [[document selection] globalRect]
									   andMask: [[document selection] mask]];
		if (scalingDir > SeaScaleDirectionNone && !translating) {
			[[document selection] scaleSelectionToRect: newRect
											  fromRect: [self preScaledRect]
									 interpolation: GIMP_INTERPOLATION_CUBIC
										 usingMask: [self preScaledMask]];
		} else if (translating && scalingDir == SeaScaleDirectionNone) {
			[[document selection] moveSelection:IntMakePoint(newRect.origin.x, newRect.origin.y)];
		}
	}
}

- (void)mouseUpAt:(IntPoint)localPoint withEvent:(NSEvent *)event
{
	if (document.selection.active) {
		[self mouseUpAt: localPoint
				forRect: [[document selection] globalRect]
				andMask: [(SeaSelection*)[document selection] mask]];
	}
}

- (void)cancelSelection
{
	translating = NO;
	scalingDir = SeaScaleDirectionNone;

	intermediate = NO;
	[[document helpers] selectionChanged];
}

@end
