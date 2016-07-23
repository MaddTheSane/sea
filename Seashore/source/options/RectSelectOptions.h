#import "Globals.h"
#import "AbstractSelectOptions.h"

@class AspectRatio;

/*!
	@class		RectSelectOptions
	@abstract	Handles the options pane for the rectangular selection tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface RectSelectOptions : AbstractSelectOptions {

	// The slider to select the radius for the rounded rectangle
	IBOutlet NSSlider *radiusSlider;
	
	// When checked indicates the rectangle should be rounded
	IBOutlet NSButton *radiusCheckbox;

	// The AspectRatio instance linked to this options panel
	IBOutlet AspectRatio *aspectRatio;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@property	radius
	@discussion	Returns the curve rdius to be used with the rounded rectangle.
	@result		Returns an integer indicating the curve radius to be used with
				the rounded rectangle.
*/
@property (readonly) int radius;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
