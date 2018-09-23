#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
 @enum		k...Dir
 @constant	kNoDir
 @constant	kULDir
 @constant	kUDir
 @constant	kURDir
 @constant	kRDir
 @constant	kDRDir
 @constant	kDDir
 @constant	kDLDir
 @constant	kLDir 
 */
typedef NS_ENUM(int, SeaScaleDirection) {
	SeaScaleDirectionNone = -1,
	SeaScaleDirectionUpperLeft,
	SeaScaleDirectionUp,
	SeaScaleDirectionUpperRight,
	SeaScaleDirectionRight,
	SeaScaleDirectionDownRight,
	SeaScaleDirectionDown,
	SeaScaleDirectionDownLeft,
	SeaScaleDirectionLeft
};


#import "AbstractTool.h"

@class AbstractScaleOptions;

/*!
	@class		AbstractScaleTool
	@abstract	Acts as a base class for all scaling/translating actions.
	@discussion	This is because this functionality is shared between all
				of the various selection tools.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
 */
@interface AbstractScaleTool : AbstractTool {
	// Are we moving
	BOOL translating;
	
	// The origin of moving
	IntPoint moveOrigin;
	
	// The old origin
	IntPoint oldOrigin;
	
	// The direction of currently scaling (if any)
	SeaScaleDirection scalingDir;
	
	// The mask of the selection before it was scaled
	unsigned char * preScaledMask;
	
	// The rectangle of the selection before it was scaled
	IntRect preScaledRect;
	
	// The rectangle after it's being scaled
	IntRect postScaledRect;

}

/*!
	@property	movingOrScaling
	@discussion	If the thing is being translated or transformed
	@result		Returns a BOOL: YES of it is moving / scaling
*/
@property (readonly, getter=isMovingOrScaling) BOOL movingOrScaling;

/*!
	@method		mouseDownAt:forRect:andMask:
	@discussion	Handles mouse down events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
*/
- (void)mouseDownAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
	@result		Returns an IntRect with the new coordinates
*/
- (IntRect)mouseDraggedTo:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
*/
- (void)mouseUpAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		point:isInHandleFor:
	@discussion	Tests to see if the point is in a handle for the given rectangle.
	@param		point
				The point to be tested.
	@param		rect
				The specified rectangle to check for handles.
*/
- (SeaScaleDirection)point:(NSPoint) point isInHandleFor:(IntRect)rect;

/*!
	@property	preScaledRect
	@discussion	For determining the previous rect for scaling.
	@result		An IntRect
*/
@property (readonly) IntRect preScaledRect;

/*!
	@property	preScaledMask
	@discussion	For determining the old mask.
	@result		An bitmap
*/
@property (readonly) unsigned char *preScaledMask NS_RETURNS_INNER_POINTER;

/*!
	@property	postScaledRect
	@discussion	For determining the rect to draw.
	@result		An IntRect
*/
@property (readonly) IntRect postScaledRect;

@end

static const SeaScaleDirection kNoDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionNone", 10.2, 10.8) = SeaScaleDirectionNone;
static const SeaScaleDirection kULDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionUpperLeft", 10.2, 10.8) = SeaScaleDirectionUpperLeft;
static const SeaScaleDirection kUDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionUp", 10.2, 10.8) = SeaScaleDirectionUp;
static const SeaScaleDirection kURDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionUpperRight", 10.2, 10.8) = SeaScaleDirectionUpperRight;
static const SeaScaleDirection kRDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionRight", 10.2, 10.8) = SeaScaleDirectionRight;
static const SeaScaleDirection kDRDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionDownRight", 10.2, 10.8) = SeaScaleDirectionDownRight;
static const SeaScaleDirection kDDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionDown", 10.2, 10.8) = SeaScaleDirectionDown;
static const SeaScaleDirection kDLDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionDownLeft", 10.2, 10.8) = SeaScaleDirectionDownLeft;
static const SeaScaleDirection kLDir NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaScaleDirectionLeft", 10.2, 10.8) = SeaScaleDirectionLeft;
