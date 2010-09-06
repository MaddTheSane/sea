#import "Globals.h"

/*!
	@class		AbstractSelectTool
	@abstract	Acts as a base class for all selection tools.
	@discussion	This tool is primarily responsible for moving selections.
				This is because this functionality is shared between all
				of the various selection tools.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "AbstractTool.h"


@interface AbstractSelectTool : AbstractTool {
	// Are we moving the selection?
	BOOL movingSelection;
	
	// The origin of moving
	IntPoint moveOrigin;
	
	// The old origin
	IntPoint oldOrigin;
	
	// Is the selection being made
	BOOL intermediate;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		intermediate
	@discussion	If the selection is currently being made.
	@result		Returns a BOOL: YES if it is being made.
*/
- (BOOL) intermediate;

/*!
	@method		selectionIsMoving
	@discussion	If the selection is currently being moved
	@result		Returns a BOOL: YES of it is moving
*/
- (BOOL) selectionIsMoving;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		cancelSelection
	@discussion	Stops making the selection
*/
- (void)cancelSelection;

@end
