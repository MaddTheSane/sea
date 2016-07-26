#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "AbstractScaleOptions.h"

@class AspectRatio;

/*!
	@class		CropOptions
	@abstract	Handles the options pane for the cropping tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface CropOptions : AbstractScaleOptions {
	/// The AspectRatio instance linked to this options panel
	IBOutlet AspectRatio *aspectRatio;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		crop:
	@discussion	Crops the image to given rectangle.
	@param		sender
				Ignored.
*/
- (IBAction)crop:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
