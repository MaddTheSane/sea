#import "Globals.h"

/*!
	@class		SeaController
	@abstract	Handles a number of special duties relating to the application's
				operation.
	@discussion	The SeaController is the sole delegate of NSApp and also
				contains a number of class methods that allow users to access
				various objects that are created by the MainMenu NIB file.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@class SeaPlugins, SeaPrefs, UtilitiesManager, SeaProxy;
@class SeaHelp, SeaWarning;

@interface SeaController : NSObject <NSApplicationDelegate>
{
	// An array of objects wishing to recieve the terminate message
	NSArray *terminationObjects;
}
	// An outlet to the utilities manager of the application
@property (weak) IBOutlet UtilitiesManager *utilitiesManager;

// An outlet to the plug-ins manager of the application
@property (weak) IBOutlet SeaPlugins *seaPlugins;

// An outlet to the preferences manager of the application
@property (weak) IBOutlet SeaPrefs *seaPrefs;

// An outlet to the proxy object of the application
@property (weak) IBOutlet SeaProxy *seaProxy;
	
// An outlet to the help manager of the application
@property (weak) IBOutlet SeaHelp *seaHelp;

// An outlet to the warning manager of the application
@property (weak) IBOutlet SeaWarning *seaWarning;

// The window containing the GNU General Public License
@property (weak) IBOutlet NSWindow *licenseWindow;

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		applicationDidFinishLaunching:
	@discussion	Called when the application finishes launching.
	@param		notification
				Ignored.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

/*!
	@method		utilitiesManager
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of UtilitiesManager.
*/
+ (UtilitiesManager *)utilitiesManager;

/*!
	@method		seaPlugins
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of SeaPlugins.
*/
+ (SeaPlugins *)seaPlugins;

/*!
	@method		seaPrefs
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of SeaPrefs.
*/
+ (SeaPrefs *)seaPrefs;

/*!
	@method		seaProxy
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of SeaProxy.
*/
+ (SeaProxy *)seaProxy;

/*!
	@method		seaHelp
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of SeaHelp.
*/
+ (SeaHelp *)seaHelp;

/*!
	@method		seaWarning
	@discussion	A class method that returns the object of the same name.
	@result		Returns the instance of SeaWarning.
*/
+ (SeaWarning *)seaWarning;

/*!
	@method		revert:
	@discussion	Implements a custom revert method that closes the current
				document and reopens it.
	@param 		sender
				Ignored.
*/
- (IBAction)revert:(id)sender;

/*!
	@method		editLastSaved:
	@discussion	Copies the current document file on disk and opens it.
	@param		sender
				Ignored.
*/
- (IBAction)editLastSaved:(id)sender;

/*!
	@method		colorSyncChanged:
	@discussion	Notifies all documents when the ColorSync preferences change.
	@param		notification
				Ignored.
*/
- (void)colorSyncChanged:(NSNotification *)notification;

/*!
	@method		showLicense:
	@discussion	Shows the license for Seashore.
	@param		sender
				Ignored.
*/
- (IBAction)showLicense:(id)sender;

/*!
	@method		newDocumentFromPasteboard:
	@discussion	Adds a new document with the contents of the pasteboard.
	@param		sender
				Ignored.
*/
- (IBAction)newDocumentFromPasteboard:(id)sender;

/*!
	@method		registerForTermination:
	@discussion	Registers any given object so that it recieves a terminate
				message before the application quits.
	@param		object
				The object that wishes to recieve a termination message (the
				object is not retained).
*/
- (void)registerForTermination:(id)object;

/*!
	@method		applicationWillTerminate:
	@discussion	Notifies all registered objects of Seashore's termination and
				also synchronizes preferences.
	@param		notification
				Ignored.
*/
- (void)applicationWillTerminate:(NSNotification *)notification;

/*!
	@method		applicationShouldOpenUntitledFile:
	@discussion	Returns whether a new document should be created when the
				application starts.
	@param		app
				Ignored.
	@result		Returns YES if a new document should be created when the
				application starts, NO otherwise.
*/
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app;

/*!
	@method		applicationOpenUntitledFile:
	@discussion	Opens a new untitled file for the application.
	@param		app
				Ignored.
	@result		Returns YES if a new document should be created when the
				application starts, NO otherwise.
*/
- (BOOL)applicationOpenUntitledFile:(NSApplication *)app;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end
