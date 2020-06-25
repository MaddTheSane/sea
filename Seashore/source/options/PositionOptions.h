#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "AbstractScaleOptions.h"

/*!
	@enum		k...Layer
	@constant	kMovingLayer
				The tool changes the position of the layer.
	@constant	kScalingLayer
				The tool scales the layer.
	@constant	kRotatingLayer
				If the layer is floating, it rotates it.
	@constant	kAnchoringLayer
				The tool anchors the floating layer.
*/

typedef NS_ENUM(int, SeaPositionOptions) {
	//! The tool changes the position of the layer.
	SeaPositionOptionMoving = 0,
	//! The tool scales the layer.
	SeaPositionOptionScaling = 1,
	//! If the layer is floating, it rotates it.
	SeaPositionOptionRotating = 2,
	//! The tool anchors the floating layer.
	SeaPositionOptionAnchoring = 3,
};


/*!
	@class		PositionOptions
	@abstract	Handles the options pane for the position tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface PositionOptions : AbstractScaleOptions {
	// Checkbox specifying whether the position tool can anchor floating selections
	IBOutlet NSButton *canAnchorCheckbox;
	
	// Function of the tool
	SeaPositionOptions function;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@property	canAnchor
	@discussion	Returns whether the position tool can anchor floating selections.
	@result		Returns YES if the position tool can anchor floating selections,
				NO otherwise.
*/
@property (readonly) BOOL canAnchor;

/*!
	@method		setFunctionFromIndex:
	@discussion	For setting the function of the tool from a modifier index (instead of a k...Layer enum).
	@param		index
				The modifier index of the new modifier.
*/
- (void)setFunctionFromIndex:(AbstractModifiers)index;

/*!
	@property	toolFunction
	@discussion	For figuring out what the tool actually does. It changes depending on the appropriate modifiers or the popup menu.
	@result		One of the elements from the k...Layer enum.
*/
@property (readonly) SeaPositionOptions toolFunction;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end

static const SeaPositionOptions kMovingLayer NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPositionOptionMoving", 10.2, 10.8) = SeaPositionOptionMoving;
static const SeaPositionOptions kScalingLayer NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPositionOptionScaling", 10.2, 10.8) = SeaPositionOptionScaling;
static const SeaPositionOptions kRotatingLayer NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPositionOptionRotating", 10.2, 10.8) = SeaPositionOptionRotating;
static const SeaPositionOptions kAnchoringLayer NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPositionOptionAnchoring", 10.2, 10.8) = SeaPositionOptionAnchoring;
