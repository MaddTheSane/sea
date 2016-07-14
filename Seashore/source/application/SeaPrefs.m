#import "SeaPrefs.h"
#import "SeaDocument.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "InfoUtility.h"
#import "SeaWarning.h"
#import "SeaView.h"
#import "Units.h"
#import "ImageToolbarItem.h"
#import "WindowBackColorWell.h"
#import "SeaHelpers.h"
#import <IOKit/graphics/IOGraphicsLib.h>

enum {
	kIgnoreResolution,
	kUse72dpiResolution,
	kUseScreenResolution
};

int memoryCacheSize;

IntPoint gScreenResolution;

static NSString*	PrefsToolbarIdentifier 	= @"Preferences Toolbar Instance Identifier";

static NSString*	GeneralPrefsIdentifier 	= @"General Preferences Item Identifier";
static NSString*	NewPrefsIdentifier 	= @"New Preferences Item Identifier";
static NSString*    ColorPrefsIdentifier = @"Color Preferences Item Identifier";

static int GetIntFromDictionaryForKey(NSDictionary *desc, NSString *key)
{
    NSNumber *value;
    int num = 0;
    
	if ((value = desc[key]) == NULL || ![value isKindOfClass:[NSNumber class]])
        return 0;
	num = value.intValue;
	
	return num;
}

CGDisplayErr GetMainDisplayDPI(CGFloat *horizontalDPI, CGFloat *verticalDPI)
{
    CGDisplayErr err = kCGErrorFailure;
	
	// Get the main display
	CGDirectDisplayID displayID = kCGDirectMainDisplay;
	CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(displayID);
	
    // Grab a connection to IOKit for the requested display
    io_connect_t displayPort = CGDisplayIOServicePort( displayID );
    if ( displayPort != MACH_PORT_NULL ) {
	
        // Find out what IOKit knows about this display
        NSDictionary *displayDict = CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, 0));
        if ( displayDict != NULL ) {
            static const double mmPerInch = 25.4;
            double horizontalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, @kDisplayHorizontalImageSize) / mmPerInch;
            double verticalSizeInInches = (double)GetIntFromDictionaryForKey(displayDict, @kDisplayVerticalImageSize) / mmPerInch;

            // Now we can calculate the actual DPI
            // with information from the displayModeDict
            *horizontalDPI = (CGFloat)CGDisplayModeGetWidth(displayMode) / horizontalSizeInInches;
            *verticalDPI = (CGFloat)CGDisplayModeGetHeight(displayMode) / verticalSizeInInches;
            err = CGDisplayNoErr;
        }
    }
	CGDisplayModeRelease(displayMode);
	
    return err;
}

@interface SeaPrefs () <NSFileManagerDelegate, NSToolbarDelegate>

@end

@implementation SeaPrefs
@synthesize runCount;
@synthesize useCheckerboard;
@synthesize memoryCacheSize;
@synthesize firstRun;
//@synthesize mode;
@synthesize guideColorIndex = guideColor;
@synthesize selectionColorIndex = selectionColor;

- (instancetype)init
{
	NSData *tempData;
	CGFloat xdpi, ydpi;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (self = [super init]) {
	
	// Get bounderies from preferences
	if ([defaults objectForKey:@"boundaries"] && [defaults boolForKey:@"boundaries"])
		layerBounds = YES;
	else
		layerBounds = NO;

	// Get bounderies from preferences
	if ([defaults objectForKey:@"guides"] && ![defaults boolForKey:@"guides"])
		guides = NO;
	else
		guides = YES;
	
	// Get rulers from preferences
	if ([defaults objectForKey:@"rulers"] && [defaults boolForKey:@"rulers"])
		rulers = YES;
	else
		rulers = NO;
	
	// Determine if this is our first run from preferences
	if ([defaults objectForKey:@"version"] == NULL)  {
		firstRun = YES;
		[defaults setObject:@"0.1.9" forKey:@"version"];
	}
	else {
		if ([[defaults stringForKey:@"version"] isEqualToString:@"0.1.9"]) {
			firstRun = NO;
		}
		else {
			firstRun = YES;
			[defaults setObject:@"0.1.9" forKey:@"version"];
		}
	}
	
	// Get run count
	if (firstRun) {
		runCount = 1;
	}
	else {
		if ([defaults objectForKey:@"runCount"])
			runCount =  [defaults integerForKey:@"runCount"] + 1;
		else
			runCount = 1;
	}

	// Get memory cache size from preferences
	memoryCacheSize = 4096;
	if ([defaults objectForKey:@"memoryCacheSize"])
		memoryCacheSize = [defaults integerForKey:@"memoryCacheSize"];
	if (memoryCacheSize < 128 || memoryCacheSize > 32768)
		memoryCacheSize = 4096;

	// Get the use of the checkerboard pattern
	if ([defaults objectForKey:@"useCheckerboard"])
		useCheckerboard = [defaults boolForKey:@"useCheckerboard"];
	else
		useCheckerboard = YES;
	
	// Get the fewerWarnings
	if ([defaults objectForKey:@"fewerWarnings"])
		fewerWarnings = [defaults boolForKey:@"fewerWarnings"];
	else
		fewerWarnings = NO;
		
	//  Get the effectsPanel
	if ([defaults objectForKey:@"effectsPanel"])
		effectsPanel = [defaults boolForKey:@"effectsPanel"];
	else
		effectsPanel = NO;
	
	//  Get the smartInterpolation
	if ([defaults objectForKey:@"smartInterpolation"])
		smartInterpolation = [defaults boolForKey:@"smartInterpolation"];
	else
		smartInterpolation = YES;
	
	//  Get the openUntitled
	if ([defaults objectForKey:@"openUntitled"])
		openUntitled = [defaults boolForKey:@"openUntitled"];
	else
		openUntitled = YES;
		
	// Get the selection colour
	selectionColor = kBlackColor;
	if ([defaults objectForKey:@"selectionColor"])
		selectionColor = [defaults integerForKey:@"selectionColor"];
	if (selectionColor < 0 || selectionColor >= kMaxColor)
		selectionColor = kBlackColor;
	
	// If the layer bounds are white (the alternative is the selection color)
	whiteLayerBounds = YES;
	if ([defaults objectForKey:@"whiteLayerBounds"])
		whiteLayerBounds = [defaults boolForKey:@"whiteLayerBounds"];

	// Get the guide colour
	guideColor = kYellowColor;
	if ([defaults objectForKey:@"guideColor"])
		guideColor = [defaults integerForKey:@"guideColor"];
	if (guideColor < 0 || guideColor >= kMaxColor)
		guideColor = kYellowColor;
	
	// Determine the initial color (from preferences if possible)
	if ([defaults objectForKey:@"windowBackColor"] == NULL) {
		windowBackColor = [NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0];
	}
	else {
		tempData = [defaults dataForKey:@"windowBackColor"];
		if (tempData != nil)
			windowBackColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData];
	}
	
	// Get the default document size
	width = 512;
	if ([defaults objectForKey:@"width"])
		width = [defaults integerForKey:@"width"];
	height = 384;
	if ([defaults objectForKey:@"height"])
		height = [defaults integerForKey:@"height"];
	
	// The resolution for new documents
	resolution = 72;
	if ([defaults objectForKey:@"resolution"])
		resolution = [defaults integerForKey:@"resolution"];
	if (resolution != 72 && resolution != 96 && resolution != 150 && resolution != 300)
		resolution = 72;
	
	// Units used in the new document
	newUnits = kPixelUnits;
	if ([defaults objectForKey:@"units"])
		newUnits = [defaults integerForKey:@"units"];
	
	// Mode used for the new document
	mode = 0;
	if ([defaults objectForKey:@"mode"])
		mode = [defaults integerForKey:@"mode"];

	// Mode used for the new document
	resolutionHandling = kUse72dpiResolution;
	if ([defaults objectForKey:@"resolutionHandling"])
		resolutionHandling = [defaults integerForKey:@"resolutionHandling"];

	//  Get the multithreaded
	if ([defaults objectForKey:@"transparentBackground"])
		transparentBackground = [defaults boolForKey:@"transparentBackground"];
	else
		transparentBackground = NO;

	//  Get the multithreaded
	if ([defaults objectForKey:@"multithreaded"])
		multithreaded = [defaults boolForKey:@"multithreaded"];
	else
		multithreaded = YES;
		
	//  Get the ignoreFirstTouch
	if ([defaults objectForKey:@"ignoreFirstTouch"])
		ignoreFirstTouch = [defaults boolForKey:@"ignoreFirstTouch"];
	else
		ignoreFirstTouch = NO;
		
	// Get the mouseCoalescing
	if ([defaults objectForKey:@"newMouseCoalescing"])
		mouseCoalescing = [defaults boolForKey:@"newMouseCoalescing"];
	else
		mouseCoalescing = YES;
		
	// Get the checkForUpdates
	if ([defaults objectForKey:@"checkForUpdates"]) {
		checkForUpdates = [defaults boolForKey:@"checkForUpdates"];
		lastCheck = [[defaults objectForKey:@"lastCheck"] doubleValue];
	}
	else {
		checkForUpdates = YES;
		lastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
	}
	
	// Get the preciseCursor
	if ([defaults objectForKey:@"preciseCursor"])
		preciseCursor = [defaults boolForKey:@"preciseCursor"];
	else
		preciseCursor = NO;

	// Get the useCoreImage
	if ([defaults objectForKey:@"useCoreImage"])
		useCoreImage = [defaults boolForKey:@"useCoreImage"];
	else
		useCoreImage = YES;
		
	// Get the main screen resolution
	if (GetMainDisplayDPI(&xdpi, &ydpi)) {
		xdpi = ydpi = 72.0;
		NSLog(@"Error finding screen resolution.");
	}
	mainScreenResolution.x = (int)roundf(xdpi);
	mainScreenResolution.y = (int)roundf(ydpi);
#ifdef DEBUG
	// NSLog(@"Screen resolution (dpi): %d x %d", mainScreenResolution.x, mainScreenResolution.y);
#endif
	gScreenResolution = [self screenResolution];
	}

	return self;
}

- (void)awakeFromNib
{
	NSString *fontName;
	float fontSize;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Get the font name and size
	if ([defaults objectForKey:@"fontName"] && [defaults objectForKey:@"fontSize"]) {
		fontName = [defaults objectForKey:@"fontName"];
		fontSize = [defaults floatForKey:@"fontSize"];
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
	}
	else {
		[[NSFontManager sharedFontManager] setSelectedFont:[NSFont messageFontOfSize:0] isMultiple:NO];
	}

	// Create the toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: PrefsToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];

    // We are the delegate
    [toolbar setDelegate: self];

    // Attach the toolbar to the document window 
    [panel setToolbar: toolbar];
	[toolbar setSelectedItemIdentifier:GeneralPrefsIdentifier];
	[(NSPanel *)panel setContentView: generalPrefsView];

	// Register to recieve the terminate message when Seashore quits
	[controller registerForTermination:self];
}

- (void)terminate
{
	NSFont *font = [[NSFontManager sharedFontManager] selectedFont];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// For some unknown reason NSColorListMode causes a crash on boot
	NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
	if([colorPanel mode] == NSColorListModeColorPanel){
		[colorPanel setMode:NSWheelModeColorPanel];
	}
	
	[defaults setBool:guides forKey:@"guides"];
	[defaults setBool:layerBounds forKey:@"boundaries"];
	[defaults setObject:(rulers ? @"YES" : @"NO") forKey:@"rulers"];
	[defaults setInteger:memoryCacheSize forKey:@"memoryCacheSize"];
	[defaults setObject:(fewerWarnings ? @"YES" : @"NO") forKey:@"fewerWarnings"];
	[defaults setObject:(effectsPanel ? @"YES" : @"NO") forKey:@"effectsPanel"];
	[defaults setObject:(smartInterpolation ? @"YES" : @"NO") forKey:@"smartInterpolation"];
	[defaults setObject:(openUntitled ? @"YES" : @"NO") forKey:@"openUntitled"];
	[defaults setObject:(multithreaded ? @"YES" : @"NO") forKey:@"multithreaded"];
	[defaults setObject:(ignoreFirstTouch ? @"YES" : @"NO") forKey:@"ignoreFirstTouch"];
	[defaults setObject:(mouseCoalescing ? @"YES" : @"NO") forKey:@"newMouseCoalescing"];
	[defaults setObject:(checkForUpdates ? @"YES" : @"NO") forKey:@"checkForUpdates"];
	[defaults setObject:(preciseCursor ? @"YES" : @"NO") forKey:@"preciseCursor"];
	[defaults setObject:(useCoreImage ? @"YES" : @"NO") forKey:@"useCoreImage"];
	[defaults setObject:(transparentBackground ? @"YES" : @"NO") forKey:@"transparentBackground"];
	[defaults setObject:(useCheckerboard ? @"YES" : @"NO") forKey:@"useCheckerboard"];
	[defaults setObject:[NSArchiver archivedDataWithRootObject:windowBackColor] forKey:@"windowBackColor"];
	[defaults setInteger:selectionColor forKey:@"selectionColor"];
	[defaults setBool:whiteLayerBounds forKey:@"whiteLayerBounds"];
	[defaults setInteger:guideColor forKey:@"guideColor"];
	[defaults setInteger:width forKey:@"width"];
	[defaults setInteger:height forKey:@"height"];
	[defaults setInteger:resolution forKey:@"resolution"];
	[defaults setInteger:newUnits forKey:@"units"];
	[defaults setInteger:mode forKey:@"mode"];
	[defaults setInteger:resolutionHandling forKey:@"resolutionHandling"];
	[defaults setInteger:runCount forKey:@"runCount"];
	[defaults setObject:[font fontName] forKey:@"fontName"];
	[defaults setFloat:[font pointSize] forKey:@"fontSize"];
	[defaults setDouble:lastCheck forKey:@"lastCheck"];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	NSToolbarItem *toolbarItem = nil;

    if ([itemIdent isEqual: GeneralPrefsIdentifier]) {
        toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: GeneralPrefsIdentifier label: LOCALSTR(@"general", @"General") imageNamed: @"GeneralPrefsIcon" toolTip: LOCALSTR(@"general prefs tooltip", @"General application settings") target: self selector: @selector(generalPrefs)];
	} else if ([itemIdent isEqual: NewPrefsIdentifier]) {
		toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: NewPrefsIdentifier label: LOCALSTR(@"new images", @"New Images") imageNamed: @"NewPrefsIcon" toolTip: LOCALSTR(@"new prefs tooltip", @"Settings for new images") target: self selector: @selector(newPrefs)];
	} else if ([itemIdent isEqual: ColorPrefsIdentifier]) {
		toolbarItem = [[ImageToolbarItem alloc] initWithItemIdentifier: ColorPrefsIdentifier label: LOCALSTR(@"color", @"Colors") image: [NSImage imageNamed:NSImageNameColorPanel] toolTip: LOCALSTR(@"color prefs tooltip", @"Display colors") target: self selector: @selector(colorPrefs)];
	}
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return @[GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return @[GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar;
{
    return @[GeneralPrefsIdentifier, NewPrefsIdentifier, ColorPrefsIdentifier];
}

- (void) generalPrefs {
	[(NSPanel *)panel setContentView: generalPrefsView];
}

- (void) newPrefs {
	[(NSPanel *)panel setContentView: newPrefsView];
}

- (void) colorPrefs {
    [(NSPanel *)panel setContentView: colorPrefsView];
}

- (IBAction)show:(id)sender
{
	// Set the existing settings
	[newUnitsMenu selectItemAtIndex: newUnits];
	[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];
	[heightUnits setStringValue:UnitsString(newUnits)];
	[resolutionMenu selectItemAtIndex:[resolutionMenu indexOfItemWithTag:resolution]];
	[modeMenu selectItemAtIndex: mode];
	[checkerboardMatrix	selectCellAtRow: useCheckerboard column: 0];
	[layerBoundsMatrix selectCellAtRow: whiteLayerBounds column: 0];
	[windowBackWell setInitialColor:windowBackColor];
	[transparentBackgroundCheckbox setState:transparentBackground];
	[fewerWarningsCheckbox setState:fewerWarnings];
	[effectsPanelCheckbox setState:effectsPanel];
	[smartInterpolationCheckbox setState:smartInterpolation];
	[openUntitledCheckbox setState:openUntitled];
	[multithreadedCheckbox setState:multithreaded];
	[ignoreFirstTouchCheckbox setState:ignoreFirstTouch];
	[coalescingCheckbox setState:mouseCoalescing];
	[checkForUpdatesCheckbox setState:checkForUpdates];
	[preciseCursorCheckbox setState:preciseCursor];	
	[useCoreImageCheckbox setState:useCoreImage];
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3) {
		[useCoreImageCheckbox setState:NO];
		[useCoreImageCheckbox setEnabled:NO];
	}
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
		[multithreadedCheckbox setState:NO];
		[multithreadedCheckbox setEnabled:NO];
	}
	[selectionColorMenu selectItemAtIndex:[selectionColorMenu indexOfItemWithTag:selectionColor + 280]];
	[guideColorMenu selectItemAtIndex:[guideColorMenu indexOfItemWithTag:guideColor + 290]];
	[resolutionHandlingMenu selectItemAtIndex:[resolutionHandlingMenu indexOfItemWithTag:resolutionHandling]];
	
	// Display the preferences dialog
	[panel center];
	[panel makeKeyAndOrderFront: self];
}

-(IBAction)setWidth:(id)sender
{
	int newWidth = PixelsFromFloat([widthValue floatValue],newUnits,resolution);
	
	// Don't accept rediculous widths
	if (newWidth < kMinImageSize || newWidth > kMaxImageSize) { 
		NSBeep(); 
		[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];
	}
	else {
		width = newWidth;
	}
	
	[self apply: self];
}

-(IBAction)setHeight:(id)sender
{
	int newHeight =  PixelsFromFloat([heightValue floatValue],newUnits,resolution);

	// Don't accept rediculous heights
	if (newHeight < kMinImageSize || newHeight > kMaxImageSize) { 
		NSBeep(); 
		[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	}
	else {
		height = newHeight;
	}
	
	[self apply: self];
}

-(IBAction)setNewUnits:(id)sender
{
	newUnits = [sender tag] % 10;
	[heightValue setStringValue:StringFromPixels(height, newUnits, resolution)];
	[widthValue setStringValue:StringFromPixels(width, newUnits, resolution)];	
	[heightUnits setStringValue:UnitsString(newUnits)];
	[self apply: self];
}

-(IBAction)changeUnits:(id)sender
{
	SeaDocument *document = gCurrentDocument;
	[document changeMeasuringStyle:[sender tag] % 10];
	[[document docView] updateRulers];
	[[[SeaController utilitiesManager] infoUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

-(IBAction)setResolution:(id)sender
{
	resolution = [[resolutionMenu selectedItem] tag];
	width =  PixelsFromFloat([widthValue floatValue],newUnits,resolution);
	height =  PixelsFromFloat([heightValue floatValue],newUnits,resolution);
	[self apply: self];
}

-(IBAction)setMode:(id)sender
{
	mode = [[modeMenu selectedItem] tag];
	[self apply: self];
}

-(IBAction)setTransparentBackground:(id)sender
{
	transparentBackground = [transparentBackgroundCheckbox state];
	[self apply: self];
}

-(IBAction)setFewerWarnings:(id)sender
{
	fewerWarnings = [fewerWarningsCheckbox state];
	[self apply: self];
}
	
-(IBAction)setEffectsPanel:(id)sender
{
	effectsPanel = [effectsPanelCheckbox state];
	[self apply: self];
}

-(IBAction)setSmartInterpolation:(id)sender
{
	smartInterpolation = [smartInterpolationCheckbox state];
	[self apply: self];
}

-(IBAction)setOpenUntitled:(id)sender
{
	openUntitled = [openUntitledCheckbox state];
	[self apply: self];
}

-(IBAction)setMultithreaded:(id)sender
{
	multithreaded = [multithreadedCheckbox state];
	[self apply: self];
}

-(IBAction)setIgnoreFirstTouch:(id)sender
{
	ignoreFirstTouch = [ignoreFirstTouchCheckbox state];
	[self apply: self];
}

-(IBAction)setMouseCoalescing:(id)sender
{
	mouseCoalescing = [coalescingCheckbox state];
	[self apply: self];
}	


-(IBAction)setCheckForUpdates:(id)sender
{
	checkForUpdates = [checkForUpdatesCheckbox state];
	[self apply: self];
}

-(IBAction)setPreciseCursor:(id)sender
{
	preciseCursor = [preciseCursorCheckbox state];
	[self apply: self];
}

- (IBAction)setUseCoreImage:(id)sender
{
	useCoreImage = [useCoreImageCheckbox state];
	[self apply: self];	
}

-(IBAction)setResolutionHandling:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	resolutionHandling = [[resolutionHandlingMenu selectedItem] tag];
	gScreenResolution = [self screenResolution];
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] helpers] resolutionChanged];
	}
}

- (IBAction)apply:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Call for all documents' views to respond to the change
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([panel isVisible]) {
		[self setWidth: self];
		[self setHeight: self];
	}
}

- (BOOL)layerBounds
{
	return layerBounds;
}

- (BOOL)guides
{
	return guides;
}

- (BOOL)rulers
{
	return rulers;
}

- (SeaWarningImportance)warningLevel
{
	return (fewerWarnings) ? kModerateImportance : kVeryLowImportance;
}

- (BOOL)effectsPanel
{
	return effectsPanel;
}

- (BOOL)smartInterpolation
{
	return smartInterpolation;
}

- (BOOL)useTextures
{
	return useTextures;
}

- (void)setUseTextures:(BOOL)value
{
	useTextures = value;
}

- (IBAction)toggleBoundaries:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	layerBounds = !layerBounds;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)toggleGuides:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	guides = !guides;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}
		
- (IBAction)toggleRulers:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	rulers = !rulers;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] updateRulersVisiblity];
	}
	[[gCurrentDocument docView] checkMouseTracking];
}

- (IBAction)checkerboardChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	useCheckerboard = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)defaultWindowBack:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	windowBackColor = [NSColor colorWithCalibratedRed:0.6667 green:0.6667 blue:0.6667 alpha:1.0];
	[windowBackWell setInitialColor:windowBackColor];
	for (i = 0; i < [documents count]; i++) {
		[documents[i] updateWindowColor];
		[[[documents[i] docView] superview] setNeedsDisplay:YES];
	}
}

- (IBAction)windowBackChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	windowBackColor = [windowBackWell color];
	for (i = 0; i < [documents count]; i++) {
		[documents[i] updateWindowColor];
		[[[documents[i] docView] superview] setNeedsDisplay:YES];
	}
}

- (NSColor *)windowBack
{
	return windowBackColor;
}

- (NSColor *)selectionColor:(CGFloat)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (selectionColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
		break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
		break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
		break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (IBAction)selectionColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	selectionColor = [sender tag] - 280;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (BOOL)whiteLayerBounds
{
	return whiteLayerBounds;
}

- (IBAction)layerBoundsColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;

	whiteLayerBounds = [sender selectedRow];
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (NSColor *)guideColor:(CGFloat)alpha
{	
	NSColor *result;
	//float alpha = light ? 0.20 : 0.40;
	
	switch (guideColor) {
		case kCyanColor:
			result = [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kMagentaColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:1.0 yellow:0.0 black:0.0 alpha:alpha];
			break;
		case kYellowColor:
			result = [NSColor colorWithDeviceCyan:0.0 magenta:0.0 yellow:1.0 black:0.0 alpha:alpha];
			break;
		default:
			result = [NSColor colorWithCalibratedWhite:0.0 alpha:alpha];
			break;
	}
	result = [result colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	return result;
}

- (IBAction)guideColorChanged:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	guideColor = [sender tag] - 290;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
}

- (IBAction)rotateSelectionColor:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	selectionColor = (selectionColor + 1) % kMaxColor;
	for (i = 0; i < [documents count]; i++) {
		[[documents[i] docView] setNeedsDisplay:YES];
	}
	
	// Set the selection colour correctly
	[selectionColorMenu selectItemAtIndex:[selectionColorMenu indexOfItemWithTag:selectionColor + 280]];
}

- (BOOL)multithreaded
{
/*
	BOOL good_os;
	
	good_os = !(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2);

	return multithreaded && good_os;
*/
	return NO;
}

- (BOOL)ignoreFirstTouch
{
	return ignoreFirstTouch;
}

- (BOOL)mouseCoalescing
{
	return mouseCoalescing;
}

- (BOOL)checkForUpdates
{
	if ([[NSDate date] timeIntervalSinceReferenceDate] - lastCheck > 7.0 * 24.0 * 60.0 * 60.0) {
		lastCheck = [[NSDate date] timeIntervalSinceReferenceDate];
		return checkForUpdates;
	}
	
	return NO;
}

- (BOOL)preciseCursor
{
	return preciseCursor;
}

- (BOOL)useCoreImage
{
	return useCoreImage;
}

- (BOOL)delayOverlay
{
	return NO;
}

- (IntSize)size
{
	IntSize result = IntMakeSize(width, height);
	
	return result;
}

- (NSInteger)resolution
{
	switch (resolution) {
		case 72:
			return 0;
		break;
		case 96:
			return 1;
		break;
		case 150:
			return 2;
		break;
		case 300:
			return 3;
		break;
		default:
			return 0;
		break;
	}
}

- (int) newUnits
{
	return newUnits;
}

- (NSInteger)mode
{
	return mode;
}

- (IntPoint)screenResolution
{
	switch (resolutionHandling) {
		case kIgnoreResolution:
			return IntMakePoint(0, 0);
		break;
		case kUse72dpiResolution:
			return IntMakePoint(72, 72);
		break;
		case kUseScreenResolution:
			return mainScreenResolution;
		break;
	}

	return IntMakePoint(72, 72);
}

- (BOOL)transparentBackground
{
	return transparentBackground;
}

- (BOOL)openUntitled
{
	return openUntitled;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	// Set the boundaries menu item appropriately
	if ([menuItem tag] == 225) {
		if (layerBounds)
			[menuItem setTitle:LOCALSTR(@"hide boundaries", @"Hide Layer Bounds")];
		else
			[menuItem setTitle:LOCALSTR(@"show boundaries", @"Show Layer Bounds")];
	}

	// Set the position guides menu item appropriately
	if ([menuItem tag] == 371) {
		if (guides)
			[menuItem setTitle:LOCALSTR(@"hide guides", @"Hide Guides")];
		else
			[menuItem setTitle:LOCALSTR(@"show guides", @"Show Guides")];
	}
	
	// Set the rulers menu item appropriately
	if ([menuItem tag] == 370) {
		if (rulers)
			[menuItem setTitle:LOCALSTR(@"hide rulers", @"Hide Rulers")];
		else
			[menuItem setTitle:LOCALSTR(@"show rulers", @"Show Rulers")];
	}

	if ([menuItem tag] >= 710 && [menuItem tag] < 720) {		
		[menuItem setState:[gCurrentDocument measureStyle] + 710 == [menuItem tag]];
	}
	
	return YES;
}

@end
