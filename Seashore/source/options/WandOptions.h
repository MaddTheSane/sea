#import "Globals.h"
#import "AbstractSelectOptions.h"

/*!
	@class		WandOptions
	@abstract	Handles the options pane for the magic wand tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface WandOptions : AbstractSelectOptions {
	
	// A slider indicating the tolerance of the wand
	IBOutlet NSSlider *toleranceSlider;
	
	// A label displaying the tolerance of the wand
	IBOutlet NSTextField *toleranceLabel;
	
	// A slider for the density of the wand sampling
	IBOutlet NSSlider *intervalsSlider;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		toleranceSliderChanged:
	@discussion	Called when the tolerance is changed.
	@param		sender
				Ignored.
*/
- (IBAction)toleranceSliderChanged:(id)sender;

/*!
	@property	tolerance
	@discussion	Returns the tolerance to be used with the paint bucket tool.
	@result		Returns an integer indicating the tolerance to be used with the
				bucket tool.
*/
@property (readonly) int tolerance;

/*!
	@property	numIntervals
	@discussion	Returns the number of intervals for the wand sampling
	@result		Returns an integer.
*/
@property (readonly) int numIntervals;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
