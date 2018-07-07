#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "Units.h"

@class SeaPrefs;

/*!
	@class		SeaDocumentController
	@abstract	Subclasses the NSDocumentController class.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2006 Mark Pazolli
*/
@interface SeaDocumentController : NSDocumentController {
	/// An outlet to the preferences manager of the application
	IBOutlet SeaPrefs *seaPrefs;
	
	/// A panel through which a new image can be configured
	IBOutlet NSPanel *newPanel;
	
	/// The various text boxes from the New Image Settings panel
	IBOutlet NSTextField *widthInput, *heightInput;
	
	/// The various buttons for changing units
	IBOutlet id widthUnits, heightUnits;
	
	/// The resolution menu from the New Image Settings panel
	IBOutlet NSPopUpButton *resMenu;
	
	/// The mode menu from the New Image Settings panel
	IBOutlet NSPopUpButton *modeMenu;
	
	/// The units menu for the New Image Settings panel
	IBOutlet NSPopUpButton *unitsMenu;
	
	/// The templates menu from the New Image Settings panel
	IBOutlet NSPopUpButton *templatesMenu;
	
	/// The transparency checkbox for the New Image settings panel
	IBOutlet NSButton *backgroundCheckbox;
	
	/// The dropdown for the recent documents.
	IBOutlet NSPopUpButton *recentMenu;
	
	/// The units for the New Image Settings panel
	SeaUnits units;
	
	/// The variables stored for retrieval by the new document
	int type, width, height, resolution;
	
	/// The variables stored for retrieval by the new document
	BOOL opaque;
	
	/// If \c YES prevents new documents being recorded as recently opened
	BOOL stopNotingRecentDocuments;
	
	/// A long list of the possible things we can write
	NSMutableDictionary<NSString*,NSSet<NSString*>*> *editableTypes;
	
	/// A long list of the possible things we can read
	NSMutableDictionary<NSString*,NSSet<NSString*>*> *viewableTypes;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		newDocument:
	@discussion	Presents the New Image Settings panel needed to create a new document.
	@param		sender
				Ignored.
*/
- (IBAction)newDocument:(id)sender;

/*!
	@method		openDocument:
	@discussion Called to open a new document (hides the New Image Settings panel).
	@param		sender
				Ignored.
*/
- (IBAction)openDocument:(id)sender;

/*!
	@method		openNonCurrentDocument:
	@discussion Called to open a file that was created from an existing one.
	@param		path
				The path of the file.
	@result		Returns an instance of the freshly opened document.
*/
- (id)openNonCurrentFile:(NSString *)path;

/*!
	@method		openRecent:
	@discussion The action from the open recent popup menu.
	@param		sender
				The path of the file.
*/
- (IBAction)openRecent:(id)sender;


/*!
	@method		noteNewRecentDocument:
	@discussion	Adds new documents to the "Open Recent" sub-menu.
	@param		aDocument
				The document to add.
*/
- (void)noteNewRecentDocument:(NSDocument *)aDocument;

/*!
	@method		createDocument:
	@discussion	Actually creates a new document based on values in the
				New Image Settings panel.
	@param		sender
				Ignored.
*/
- (IBAction)createDocument:(id)sender;

/*!
	@method		changeToTemplate:
	@discussion	Called to change to a template when a menu item is selected from
				the templates menu.
	@param		sender
				Ignored.
*/
- (IBAction)changeToTemplate:(id)sender;

/*!
	@method		changeUnits:
	@discussion	Called to change the units in the New Image Settings panel.
	@param		sender
				Ignored.
*/
- (IBAction)changeUnits:(id)sender;

/*!
	@method		addDocument:
	@discussion	Adds a document to the list of open documents.
	@param		document
				The document to add.
*/
- (void)addDocument:(NSDocument *)document;

/*!
	@method		removeDocument:
	@discussion	Removes a document from the list of open documents.
	@param		document
				The document to remove.
*/
- (void)removeDocument:(NSDocument *)document;

/*!
	@method		type
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
- (int)type;
@property (readonly) int type;

/*!
	@property	width
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
@property (readonly) int width;

/*!
	@property	height
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
@property (readonly) int height;

/*!
	@property	resolution
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
@property (readonly) int resolution;

/*!
	@property	opaque
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
@property (readonly) BOOL opaque;

/*!
	@property	units
	@discussion	Returns the instance variable of the same name.
	@result		Returns the instance variable of the same name.
*/
@property (readonly) SeaUnits units;

/*!
	@property	editableTypes
	@discussion	The file types this document controller can open and save to.
	@result		A dict of file extensions, UTI's, and document type strings.
*/
@property (readonly, copy) NSMutableDictionary<NSString*,NSSet<NSString*>*>* editableTypes;

/*!
	@property	viewableTypes
	@discussion	The file types this document controller can open.
	@result		A dict of file extensions, UTI's, and document type strings.
*/
@property (readonly, copy) NSMutableDictionary<NSString*,NSSet<NSString*>*>* viewableTypes;

/*!
	@property	readableTypes
	@discussion	All of the kinds of type strings we can read in.
	@result		Flat list of all of the types.
*/
@property (readonly, copy) NSArray<NSString*> *readableTypes;

/*!
	@method		type:isContainedInDocType:
	@discussion	For determining if a type string is actually of a certain doc type
	@param		type
				The type string we're geting (a file extension, UTI, doc type)
	@param		key
				The known doc type we want to see if we're part of
	@result		Whether or not type is actually of type key.
*/
- (BOOL)type:(NSString *)type isContainedInDocType:(NSString*) key;


@end
