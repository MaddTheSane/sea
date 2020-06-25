#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "SeaTools.h"

NS_ASSUME_NONNULL_BEGIN

@class SeaDocument;
@class ToolboxUtility;
@class AbstractOptions;
@class LassoOptions;
@class PolygonLassoOptions;
@class PositionOptions;
@class ZoomOptions;
@class PencilOptions;
@class BrushOptions;
@class BucketOptions;
@class TextOptions;
@class EyedropOptions;
@class RectSelectOptions;
@class EllipseSelectOptions;
@class EraserOptions;
@class SmudgeOptions;
@class GradientOptions;
@class WandOptions;
@class CloneOptions;
@class CropOptions;
@class EffectOptions;

/*!
	@class		OptionsUtility
	@abstract	Displays the options for the current tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@interface OptionsUtility : NSObject {
	// The options view
    IBOutlet NSView *view;
		
	// The last options view set 
	__unsafe_unretained __kindof NSView *lastView;

	// The document which is the focus of this utility
	IBOutlet SeaDocument *document;
	
	// The view to show when no document is active
	IBOutlet NSView *blankView;
	
	// The various options objects
	IBOutlet LassoOptions *lassoOptions;
	IBOutlet PolygonLassoOptions *polygonLassoOptions;
	IBOutlet PositionOptions *positionOptions;
	IBOutlet ZoomOptions *zoomOptions;
	IBOutlet PencilOptions *pencilOptions;
	IBOutlet BrushOptions *brushOptions;
    IBOutlet BucketOptions *bucketOptions;
	IBOutlet TextOptions *textOptions;
	IBOutlet EyedropOptions *eyedropOptions;
	IBOutlet RectSelectOptions *rectSelectOptions;
	IBOutlet EllipseSelectOptions *ellipseSelectOptions;
	IBOutlet EraserOptions *eraserOptions;
	IBOutlet SmudgeOptions *smudgeOptions;
	IBOutlet GradientOptions *gradientOptions;
	IBOutlet WandOptions *wandOptions;
	IBOutlet CloneOptions *cloneOptions;
	IBOutlet CropOptions *cropOptions;
	IBOutlet EffectOptions *effectOptions;
	
	// The toolbox utility object
	IBOutlet ToolboxUtility *toolboxUtility;
	
	// The currently active tool - not a reliable indication (see code)
	SeaToolsDefines currentTool;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

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
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@property	currentOptions
	@discussion	Returns the currently active options object.
	@result		Returns the currently active options object (NULL if none).
*/
@property (readonly, nullable) __kindof AbstractOptions *currentOptions;

/*!
	@method		getOptions:
	@discussion	Returns the options object associated with a given tool.
	@param		whichTool
				The tool type whose options object you are seeking (see
				SeaTools).
	@result		Returns the options object associated with the given index.
*/
- (nullable __kindof AbstractOptions*)getOptions:(SeaToolsDefines)whichTool;

/*!
	@method		update
	@discussion	Updates the utility and the active options object.
*/
- (void)update;

/*!
	@method		show:
	@discussion	Shows the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)show:(nullable id)sender;

/*!
	@method		hide:
	@discussion	Hides the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)hide:(nullable id)sender;

/*!
	@method		toggle:
	@discussion	Toggles the visibility of the options bar.
	@param		sender
				Ignored.
*/
- (IBAction)toggle:(nullable id)sender;


/*!
	@method		viewNeedsDisplay
	@discussion	Informs the view it needs display.
*/
- (void)viewNeedsDisplay;

/*!
	@property	visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
@property (readonly, getter=isVisible) BOOL visible;

@end

NS_ASSUME_NONNULL_END
