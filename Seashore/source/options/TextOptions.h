#import "Globals.h"
#import "AbstractPaintOptions.h"

@class SeaProxy;

/*!
	@class		TextOptions
	@abstract	Handles the options pane for the text tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface TextOptions : AbstractPaintOptions {
	// The proxy object
	IBOutlet SeaProxy *seaProxy;

	// The pop-up menu specifying the alignment to be used
	IBOutlet NSSegmentedControl *alignmentControl;

	// The checkbox specifying the outline of the font
	IBOutlet NSButton *outlineCheckbox;
	
	// The slider specifying the outline of the font
	IBOutlet NSSlider *outlineSlider;
		
	// A label specifying the font
	IBOutlet NSTextField *fontLabel;
	
	// The checkbox specifying whether a fringe is okay
	IBOutlet NSButton *fringeCheckbox;
	
	// The font manager associated with the text tool
	NSFontManager *fontManager;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		showFonts:
	@discussion	Shows the fonts panel to select the font to be used for the
				text.
	@param		sender
				Ignored.
*/
- (IBAction)showFonts:(id)sender;

/*!
	@method		changeFont:
	@discussion	Handles a change in the selected font.
	@param		sender
				Ignored.
*/
- (IBAction)changeFont:(id)sender;

/*!
	@property	alignment
	@discussion	Returns the alignment to be used with the text tool.
	@result		Returns an \c NSTextAlignment representing an alignment type.
*/
@property (readonly) NSTextAlignment alignment;

/*!
	@property	useSubpixel
	@discussion	Returns whether subpxiel rendering should be used.
	@result		Returns \c YES if subpixel rendering should be used, \c NO otherwise.
*/
@property (readonly) BOOL useSubpixel;

/*!
	@property	outline
	@discussion	Returns the number of points the outline should be.
	@result		Returns an integer indicating the number of points the outline should be
				or zero if outline is disabled.
*/
@property (readonly) int outline;

/*!
	@property	useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
@property (readonly) BOOL useTextures;

/*!
	@property	allowFringe
	@discussion	Returns whether a fringe is allowed, the fringe is determined using
				the background layers and will look out of place if the background
				changes. On the other hand, the fringe will look better if the
				background does not change.
	@result		Returns YES if the fringe should be allowed, NO otherwise.
*/
@property (readonly) BOOL allowFringe;

/*!
	@method		update
	@discusison	Updates the options and tool after a change.
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
