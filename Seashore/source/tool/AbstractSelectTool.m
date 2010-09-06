#import "AbstractSelectTool.h"
#import "AbstractTool.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "AbstractSelectOptions.h"
#import "SeaSelection.h"
#import "AbstractSelectTool.h"
#import "SeaDocument.h"
#import "SeaHelpers.h"

@implementation AbstractSelectTool
- (id)init
{
	if (![super init])
		return NULL;

	intermediate = NO;
	movingSelection = NO;
	
	return self;
}

- (BOOL) intermediate
{
	return intermediate;
}

- (BOOL) selectionIsMoving
{
	return movingSelection;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	// Check if location is in existing rect
	movingSelection = NO;
	if ([[document selection] active] && [(AbstractSelectOptions *)options selectionMode] == kDefaultMode && IntPointInRect(where, [[document selection] localRect])) {
		movingSelection = YES;
		moveOrigin = where;
		oldOrigin =  [[document selection] trueLocalRect].origin;
	}
	intermediate = YES;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	if (movingSelection && intermediate) {
		IntPoint newOrigin;
		// Move the selection
		newOrigin.x = oldOrigin.x + (where.x - moveOrigin.x);
		newOrigin.y = oldOrigin.y + (where.y - moveOrigin.y);
		[[document selection] moveSelection:newOrigin];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	
}

- (void)cancelSelection
{
	intermediate = NO;
	movingSelection = NO;
	[[document helpers] selectionChanged];
}

@end
