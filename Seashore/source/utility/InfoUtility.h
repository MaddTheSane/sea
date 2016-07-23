#import "Globals.h"

/*!
	@enum		kMeasure...
	@constant	kMeasurePixels
				Measure using pixels.
	@constant	kMeasureInches
				Measure using inches.
	@constant	kMeasureMillimeters
				Measure using millimetres.
*/
enum {
	kMeasurePixels = 0,
	kMeasureInches = 1,
	kMeasureMillimeters = 2
};

@class SeaDocument;
@class LayerControlView;

/*!
	@class		InfoUtility
	@abstract	Displays information about the cursor position and the pixel
				underneath that cursor.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface InfoUtility : NSObject {
	
	// The document which is the focus of this utility
	IBOutlet SeaDocument *document;
	
	// Displays the red, green, blue and alpha value of the focused pixel
	IBOutlet NSTextField *redValue;
    IBOutlet NSTextField *greenValue;
    IBOutlet NSTextField *blueValue;
    IBOutlet NSTextField *alphaValue;
	IBOutlet NSColorWell *colorWell;
	
	// Displays the x and y co-ordinates of the cursor
    IBOutlet NSTextField *xValue;
    IBOutlet NSTextField *yValue;
	IBOutlet NSTextField *widthValue;
    IBOutlet NSTextField *heightValue;
	IBOutlet NSTextField *deltaX;
	IBOutlet NSTextField *deltaY;
	IBOutlet NSTextField *radiusValue;

	// The active measuring style
	int measureStyle;

	// The approprate views
	IBOutlet NSView *view;
	IBOutlet LayerControlView *controlView;
	IBOutlet NSButton *toggleButton;

}

/*!
	@method		awakeFromNib
	@discussion	Configures the utility's interface.
*/
- (void)awakeFromNib;

/*!
	@method		shutdown
	@discussion	Saves current transparency colour upon shutdown.
*/
- (void)shutdown;

/*!
	@method		activate
	@discussion	Activates this utility with its document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		show:
	@discussion	Shows the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		hide:
	@discussion	Hides the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)hide:(id)sender;

/*!
	@method		toggle:
	@discussion	Toggles the visibility of the utility's window.
	@param		sender
				Ignored.
*/
- (IBAction)toggle:(id)sender;

/*!
	@method		update
	@discussion	Updates the utility to reflect the current cursor position and
				associated data.
*/
- (void)update;

/*!
	@method		visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
- (BOOL)visible;

@end
