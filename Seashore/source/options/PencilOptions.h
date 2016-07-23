#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		PencilOptions
	@abstract	Handles the options pane for the pencil tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PencilOptions : AbstractPaintOptions
{	
	// A slider indicating the size of the pencil block
	IBOutlet NSSlider *sizeSlider;
}

// Are we erasing stuff?
@property (readonly) BOOL pencilIsErasing;

/*!
	@property	pencilSize
	@discussion	Returns the current pencil size.
	@result		Returns an integer representing the current pencil size.
*/
@property (readonly) int pencilSize;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		updateModifiers:
	@discussion	Updates the modifier pop-up.
	@param		modifiers
				An unsigned int representing the new modifiers.
*/
- (void)updateModifiers:(NSEventModifierFlags)modifiers;

/*!
	@method		modifierPopupChanged:
	@discussion	Called when the popup is changed.
	@param		sender
				Needs to be the popup menu.
*/
- (IBAction)modifierPopupChanged:(id)sender;


/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
