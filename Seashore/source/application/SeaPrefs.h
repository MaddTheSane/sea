#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "SSKTerminatable.h"
#import "Globals.h"
#import "SeaWarning.h"
#import "Units.h"
#else
#import <SeashoreKit/SSKTerminatable.h>
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/SeaWarning.h>
#import <SeashoreKit/Units.h>
#endif

/*!
	@enum		k...Color
	@constant	SeaGuideColorCyan
				The colour cyan.
	@constant	SeaGuideColorMagenta
				The colour magenta.
	@constant	SeaGuideColorYellow
				The colour yellow.
	@constant	SeaGuideColorBlack
				The colour black.
	@constant	SeaGuideColorMax
				A marker indicating the last possible colour plus one.
*/
typedef NS_ENUM(NSInteger, SeaGuideColor) {
	SeaGuideColorCyan,
	SeaGuideColorMagenta,
	SeaGuideColorYellow,
	SeaGuideColorBlack,
	SeaGuideColorMax,
};

@class SeaController;
@class WindowBackColorWell;

/*!
	@class		SeaPrefs
	@abstract	Handles a number of Seashore's preferences.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaPrefs : NSObject <SSKTerminatable, NSMenuItemValidation> {
	
	// The SeaController object
	IBOutlet SeaController *controller;
	
	// The preferences panel
	IBOutlet NSPanel *panel;
	
	// The general prefs view
	IBOutlet NSView *generalPrefsView;
	
	// The new prefs view
	IBOutlet NSView *newPrefsView;
	
	// The color prefs view
	IBOutlet NSView *colorPrefsView;
	
	// A checkbox which when checked indicates that there should be fewer warnings
	IBOutlet NSButton *fewerWarningsCheckbox;
	
	// The menu for selecting the selection colour
	IBOutlet NSPopUpButton *selectionColorMenu;

	// The menu for selecting the guide colour
	IBOutlet NSPopUpButton *guideColorMenu;
	
	// The matrix button for the checkrboard pattern
	IBOutlet NSMatrix *checkerboardMatrix;

	// The matrix button for the color of the layer bounds
	IBOutlet NSMatrix *layerBoundsMatrix;
		
	// The color well for the window back
	IBOutlet WindowBackColorWell *windowBackWell;
	
	// The text field for the suggested width value for a new image
	IBOutlet NSTextField *widthValue;
	
	// The text field for the suggested height value for a new image
	IBOutlet NSTextField *heightValue;
	
	// The units label for the height
	IBOutlet NSTextField *heightUnits;
	
	// The menu for the default units
	IBOutlet NSPopUpButton *newUnitsMenu;
	
	// The menu for the current units
	IBOutlet NSPopUpButton *docUnitsMenu;
	
	// The menu for the default resolution
	IBOutlet NSPopUpButton *resolutionMenu;
	
	// The menu for the mode
	IBOutlet NSPopUpButton *modeMenu;
	
	// The menu for resolution handling
	IBOutlet NSPopUpButton *resolutionHandlingMenu;
	
	// The checkbox for transparency
	IBOutlet NSButton *transparentBackgroundCheckbox;
	
	// A checkbox which when checked indicates effects should use a panel not a sheet
	IBOutlet NSButton *effectsPanelCheckbox;
	
	// A checkbox which when checked indicates smart interpolations should be used
	IBOutlet NSButton *smartInterpolationCheckbox;
	
	// A checkbox which when checked indicates a new document should be created at start-up
	IBOutlet NSButton *openUntitledCheckbox;

	// A checkbox which when checked indicates the first pressure sensitive touch should be ignored
	IBOutlet NSButton *ignoreFirstTouchCheckbox;
	
	// A checkbox which when checked indicates drawing should be multithreaded
	IBOutlet NSButton *multithreadedCheckbox;
	
	// A checkbox which when checked indicates mouse coalescing should always be on
	IBOutlet NSButton *coalescingCheckbox;
	
	// A checkbox which when checked indicates updates should be checked for weekly
	IBOutlet NSButton *checkForUpdatesCheckbox;
	
	// A checkbox which when checks indicates the precise cursor should be used
	IBOutlet NSButton *preciseCursorCheckbox;
	
	// A checkbox which when checks indicates CoreImage should be used for scaling/rotation
	IBOutlet NSButton *useCoreImageCheckbox;
	
	// Stores whether or not layer boundaries are visible
	BOOL layerBounds;

	// Stores whether or not guides are visible
	BOOL guides;

	// Stores whether or not rulers are visible
	BOOL rulers;
	
	// Stores whether or not to use the checkerboard
	BOOL useCheckerboard;
	
	// The color of the back of the window
	NSColor *windowBackColor;
	
	// Is this the first run?
	BOOL firstRun;
	
	// Stores the memory cache size
	size_t memoryCacheSize;
	
	// Whether textures should be used
	BOOL useTextures;
		
	// Whether fewer warnings should be shown
	BOOL fewerWarnings;
	
	// Whether effects should appear as a panel or a sheet
	BOOL effectsPanel;
	
	// Whether smart interpolation should be used
	BOOL smartInterpolation;
	
	// Whether to check for updates weekly
	BOOL checkForUpdates;
	
	// Whether to create a new document at start-up
	BOOL openUntitled;
	
	// Whether the precise cursor should be used
	BOOL preciseCursor;
	
	// Whether Core Image should be used for scaling/rotation
	BOOL useCoreImage;
	
	// The current selection colour
	SeaGuideColor selectionColor;

	// Whether or not the layer bounds are white
	BOOL whiteLayerBounds;
	
	// The current guide colour
	NSInteger guideColor;

	// The standard width and height for a new document
	int width, height;
	
	// The standard resolution for a new document
	int resolution;
	
	// The standard units for a new document
	SeaUnits newUnits;

	// The mode used for a new document
	NSInteger mode;
	
	// How resolutions are handled
	NSInteger resolutionHandling;
	
	// Whether images sholud have a transparent background
	BOOL transparentBackground;

	// Stores the number of times this version of Seashore has been run
	NSInteger runCount;
	
	// The time of the last check
	NSTimeInterval lastCheck;
	
	// Whether drawing should be multithreaded
	BOOL multithreaded;
	
	// Whether the first pressure-sensitive touch should be ignored
	BOOL ignoreFirstTouch;

	// Whether mouse coalescing should always be on or not
	BOOL mouseCoalescing;

	// The toolbar
	NSToolbar *toolbar;
	
	// The main screen resolution
	IntPoint mainScreenResolution;
	
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		awakeFromNib
	@discussion	Configures the interface.
*/
- (void)awakeFromNib;

/*!
	@method		terminate
	@discussion	Saves preferences to disk (this method is called before the
				application exits by the SeaController).
*/
- (void)terminate;

/*!
	@method		show:
	@discussion	Shows the preferences panel.
	@param		sender
				Ignored.
*/
- (IBAction)show:(id)sender;

/*!
	@method		generalPrefs
	@discussion	Shows the general preferences.
*/
- (void) generalPrefs;

/*!
	@method		newPrefs
	@discussion	Shows the new preferences.
*/
- (void) newPrefs;

/*!
	@method		colorPrefs
	@discussion	Shows the color preferences.
*/
- (void) colorPrefs;
 

/*!
	@method		setWidth:
	@discussion	Sets the default width.
	@param		sender
				Ignored.
*/
-(IBAction)setWidth:(id)sender;

/*!
	@method		setHeight:
	@discussion	Sets the default height.
	@param		sender
				 Ignored.
*/
-(IBAction)setHeight:(id)sender;

/*!
	@method		setNewUnits:
	@discussion	Sets the default units for new documents.
	@param		sender
				Ignored.
*/
-(IBAction)setNewUnits:(id)sender;


/*!
	@method		changeUnits:
	@discussion	Changes the current application units to the sender's tag.
	@param		sender
				The NSMenuItem whose tag has the units.
*/
-(IBAction)changeUnits:(id)sender;

/*!
	@method		setResolution:
	@discussion	Sets the default resolution.
	@param		sender
				Ignored.
*/
-(IBAction)setResolution:(id)sender;

/*!
	@method		setMode:
	@discussion	Sets the default mode.
	@param		sender
				Ignored.
*/
-(IBAction)setMode:(id)sender;

/*!
	@method		setTransparentBackground:
	@discussion	Sets the default background.
	@param		sender
				Ignored.
*/
-(IBAction)setTransparentBackground:(id)sender;

/*!
	@method		setFewerWarnings:
	@discussion	Sets if fewer warnings are wanted.
	@param		sender
				Ignored.
*/
-(IBAction)setFewerWarnings:(id)sender;

/*!
	@method		setEffectsPanel:
	@discussion	Sets if the effects panels should be dialogues.
	@param		sender
				Ignored.
*/
-(IBAction)setEffectsPanel:(id)sender;

/*!
	@method		setSmartInterpolation:
	@discussion	Sets if smart interpolation should be used.
	@param		sender
				Ignored.
*/
-(IBAction)setSmartInterpolation:(id)sender;

/*!
	@method		setOpenUntitled:
	@discussion	Sets if a new document should be created at start-up.
	@param		sender
				Ignored.
*/
-(IBAction)setOpenUntitled:(id)sender;

/*!
	@method		setMultithreaded:
	@discussion	Sets if multithreaded.
	@param		sender
				Ignored.
*/
-(IBAction)setMultithreaded:(id)sender;

/*!
	@method		setIgnoreFirstTouch:
	@discussion	Sets if ignore first touch.
	@param		sender
				Ignored.
*/

-(IBAction)setIgnoreFirstTouch:(id)sender;

/*!
	@method		setMouseCoalescing:
	@discussion	Sets mouse coalescing.
	@param		sender
				Ignored.
*/
-(IBAction)setMouseCoalescing:(id)sender;

/*!
	@method		setCheckForUpdates:
	@discussion	Sets if updates should be checked for.
	@param		sender
				Ignored.
*/
-(IBAction)setCheckForUpdates:(id)sender;

/*!
	@method		setPreciseCursor:
	@discussion	Sets if use a precise cursor.
	@param		sender
				Ignored.
*/
-(IBAction)setPreciseCursor:(id)sender;

/*!
	@method		setUseCoreImage:
	@discussion	Sets if CoreImage should be used for scaling/rotating.
	@param		sender
				Ignored.
*/
- (IBAction)setUseCoreImage:(id)sender;

/*!
	@method		apply:
	@discussion	Applies the settings of the preferences panel.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		windowWillClose:
	@discussion	Notification telling us the window will close. Needed because the text field does not automatically commit.
	@param		aNotification
				Ignored.
*/
- (void)windowWillClose:(NSNotification *)aNotification;

/*!
	@property	layerBounds
	@discussion	Returns whether or not the layer boundaries should be visible.
	@result		YES if the layer boundaries should be visible, NO otherwise.
*/
@property (readonly) BOOL layerBounds;

/*!
	@property	guides
	@discussion	Returns whether or not the layer guides should be visible.
	@result		YES if the layer guides should be visible, NO otherwise.
*/
@property (readonly) BOOL guides;

/*!
	@property	rulers
	@discussion	Returns whether or not the rulers should be visible.
	@result		YES if the rulers should be visible, NO otherwise.
*/
@property (readonly) BOOL rulers;

/*!
	@property	firstRun
	@discussion	Returns if this is the first time the application has been run
				actually returns if the firstRun" boolean in user defaults is
				YES).
	@result		YES if it is the first time, NO otherwise.
*/
@property (readonly) BOOL firstRun;

/*!
	@property	memoryCacheSize
	@discussion	Returns the minimum size of the undo data for a paticular layer
				that should be stored in memory before it is written to disk.
				This is known as the memory cache size for that layer.
	@result		Returns an integer representing the memory cache size in  bytes
				for any layer.
*/
@property (readonly) size_t memoryCacheSize;

/*!
	@property	warningLevel
	@discussion	Returns the warning level. Only warnings with a priority less
				than the returned to level shoule be displayed.
	@result		Returns an integer indicating the warning level.
*/
@property (readonly) SeaWarningImportance warningLevel;

/*!
	@method		effectsPanel
	@discussion	Returns whether effects should appear as a panel or a sheet.
	@result		Returns YES if they should appear as a panel, NO otherwise.
*/
- (BOOL)effectsPanel;

/*!
	@method		smartInterpolation
	@discussion	Returns whether smart interpolation should be used.
	@result		Returns YES if smart interpolation should be used, NO otherwise.
*/
- (BOOL)smartInterpolation;

/*!
	@method		useTextures
	@discussion	Returns whether textures should be used where possible.
	@result		Returns YES if textures should be used, NO otherwise.
*/
- (BOOL)useTextures;

/*!
	@method		setUseTextures:
	@discussion	Sets whether textures should be used where possible.
	@param		value
				YES if textures should be used, NO otherwise.
*/
- (void)setUseTextures:(BOOL)value;

//! Returns whether textures should be used where possible.
@property BOOL useTextures;

/*!
	@method		toggleBoundaries:
	@discussion	Toggles whether or not the layer boundaries are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleBoundaries:(id)sender;

/*!
	@method		toggleGuides:
	@discussion	Toggles whether or not the layer guides are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleGuides:(id)sender;

/*!
	@method		toggleRulers:
	@discussion	Toggles whether or not the rulers are visible.
	@param		sender
				Ignored.
*/
- (IBAction)toggleRulers:(id)sender;

/*!
	@method		checkerboardChanged:
	@discussion	Called when whether we're using the checkerboard background changes.
	@param		sender
				The NSMatrix sending the message.
*/
- (IBAction)checkerboardChanged:(id)sender;

/*!
	@property	useCheckerboard
	@discussion	Whether the transparency should be represented by a pattern.
	@result		True if a pattern; false would use the transparency color.
*/
@property (readonly) BOOL useCheckerboard;

/*!
	@method		defaultWindowBack:
	@discussion	Called to the window back color to the default color.
	@param		sender
				The Color Well sending the message.
*/
- (IBAction)defaultWindowBack:(id)sender;

/*!
	@method		windowBackChanged:
	@discussion	Called when the window back color changes.
	@param		sender
				The Color Well sending the message.
*/
- (IBAction)windowBackChanged:(id)sender;

/*!
	@method		windowBack
	@discussion	Returns the color of the window backing (outside the image).
	@result		Returns a RGB NSColor object representing the color.
*/
- (NSColor *)windowBack;

/*!
	@method		selectionColor
	@discussion	Returns the current selection colour.
	@param		alpha
				The alpha value to be associated with the colour.
	@result		Returns a RGB NSColor object representing the selection colour.
*/
- (NSColor *)selectionColor:(CGFloat)alpha NS_SWIFT_NAME(selectionColor(alpha:));

/*!
	@property	selectionColorIndex
	@discussion	Returns the index of the current selection colour.
	@result		Returns an integer representing the selection colour.
*/
@property (readonly) SeaGuideColor selectionColorIndex;

/*!
	@method		selectionColorChanged:
	@discussion	Called when the selection colour is changed.
	@param		sender
				The menu item which caused the change in selection colour. Its
				tag should equal the desired selection colour plus 280.
*/
- (IBAction)selectionColorChanged:(id)sender;

/*!
	@method		rotateSelectionColor:
	@discussion	Rotates the current selection colour.
	@param		sender
				Ignored.
*/
- (IBAction)rotateSelectionColor:(id)sender;



- (BOOL)whiteLayerBounds;
- (IBAction)layerBoundsColorChanged:(id)sender;

/*!
 @method		guideColor
 @discussion	Returns the current guide colour.
 @param		alpha
				The alpha value to be associated with the colour.
 @result		Returns a RGB NSColor object representing the guide colour.
 */
- (NSColor *)guideColor:(CGFloat)alpha NS_SWIFT_NAME(guideColor(alpha:));

/*!
 @property		guideColorIndex
 @discussion	Returns the index of the current guide colour.
 @result		Returns an integer representing the guide colour.
 */
@property (readonly) NSInteger guideColorIndex;

/*!
 @method		guideColorChanged:
 @discussion	Called when the guide colour is changed.
 @param			sender
				The menu item which caused the change in guide colour. Its
				tag should equal the desired guide colour plus 290.
 */
- (IBAction)guideColorChanged:(id)sender;

/*!
	@property	multithreaded
	@discussion	Returns whether drawing should be multithreaded.
	@result		Returns YES if drawing should be multithreaded, NO otherwise.
*/
@property (readonly) BOOL multithreaded;

/*!
	@property	ignoreFirstTouch
	@discussion	Returns whether the first pressure-sensitive touch should be
				ignored.
	@result		Returns YES if it should be ignored, NO otherwise.
*/
@property (readonly) BOOL ignoreFirstTouch;

/*!
	@property	mouseCoalescing
	@discussion	Returns whether mouse coalescing should always be on.
	@result		Returns YES if it should always be on, NO otherwise.
*/
@property (readonly) BOOL mouseCoalescing;

/*!
	@property	checkForUpdates
	@discussion	Returns whether an application should check for updates. This
				will only return YES if it's been more than a week since the
				last update.
	@result		Returns YES if Seashore should check for updates, NO otherwise.
*/
@property (readonly) BOOL checkForUpdates;

/*!
	@property	preciseCursor
	@discussion	Returns whether a precise cursor should be used.
	@result		Returns YES if the precise cursor should be used, NO otherwise.
*/
@property (readonly) BOOL preciseCursor;

/*!
	@property	useCoreImage
	@discussion	Returns whether Core Image should be used for scaling/rotation.
	@result		Returns YES if Core Image should be used for scaling/rotation, NO otherwise.
*/
@property (readonly) BOOL useCoreImage;

/*!
	@method		delayOverlay
	@discussion	Returns whether the application of the overlay should be
				delayed.
	@result		Returns YES if it the application of the overlay should be
				delayed, NO otherwise.
*/
- (BOOL)delayOverlay;

/*!
	@method		size
	@discussion Returns the size for new images.
	@result		Returns an IntSize representing the size for new images.
*/
- (IntSize)size;

/*!
	@method		resolution
	@discussion Returns the menu item index of the resolution for new images.
	@result		Returns the menu item index of the resolution for new images.
*/
- (NSInteger)resolution;

/*!
	@method		mode
	@discussion Returns the menu item index of the mode for new images.
	@result		Returns the menu item index of the mode for new images.
*/
- (NSInteger)mode;
//@property (readonly) NSInteger mode;

/*!
	@method		screenResolution
	@discussion	Returns the screen resolution to be used when calculating view size.
				Considers resolution handling preference.
	@return		Returns either (0, 0) (ignore image resolution), (72, 72) (assume 72 dpi)
				or the true screen resolution.
*/
- (IntPoint)screenResolution;

/*!
	@property	transparentBackground
	@discussion Returns whether the background should be transparent.
	@result		Returns YES for transparency.
*/
@property (readonly) BOOL transparentBackground;

/*!
	@property	newUnits
	@discussion Returns the units used for new images.
	@result		Returns an int that represents the units (see SeaDocument).
*/
@property (readonly) SeaUnits newUnits;

/*!
	@property	runCount
	@discussion	Returns the number of times this version of Seashore has run.
	@result		Returns an integer indicating the number of times this version
				of Seashore has run.
*/
@property (readonly) NSInteger runCount;

/*!
	@property	openUntitled
	@discussion	Returns whether a new document should be created at
				start-up.
	@result		Returns YES if the a new document should be created, NO otherwise.
*/
@property (readonly) BOOL openUntitled;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@end
