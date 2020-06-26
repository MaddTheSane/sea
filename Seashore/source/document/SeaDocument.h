#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#import "AbstractExporter.h"
#import "Units.h"
#else
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/AbstractExporter.h>
#import <SeashoreKit/Units.h>
#endif

@class SeaSelection, SeaWhiteboard;

@class GIFExporter, JPEGExporter, JP2Exporter, PNGExporter, TIFFExporter, XCFExporter;
@class TextureExporter;
@class SeaContent, SeaView;
@class SeaOperations;
@class SeaHelpers;
@class SeaTools;
@class PluginData;
@class TextureExporter;
@class BrushExporter;
@class WarningsUtility;
@class LayerDataSource;
@class SeaWarning;
@class SeaView;

NS_ASSUME_NONNULL_BEGIN

/*!
	@class		SeaDocument
	@abstract	Represents a single Seashore document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaDocument : NSDocument <NSWindowDelegate>
{
	/// The selection manager for this document
	SeaSelection *selection;
	
	/// An outlet to the view associated with this document
	IBOutlet NSScrollView *view;
	
	/// An outlet to the window associated with this document
	IBOutlet NSWindow *docWindow;
	
	// The exporters
	IBOutlet GIFExporter *gifExporter;
	IBOutlet JPEGExporter *jpegExporter;
	IBOutlet JP2Exporter *jp2Exporter;
	IBOutlet PNGExporter *pngExporter;
	IBOutlet TIFFExporter *tiffExporter;
	IBOutlet XCFExporter *xcfExporter;
	
	/// An array of all possible exporters
	NSArray<id<AbstractExporter>> *exporters;
	
	/// The view to attach to the save panel
	IBOutlet NSView *accessoryView;
	
	/// A pop-up menu of all possible exporters
	IBOutlet NSPopUpButton *exportersPopUp;
	
	/// The button showing the options for the exporter
	IBOutlet NSButton *optionsButton;
	
	/// A summary of the export options
	IBOutlet id optionsSummary;
	
	/// The Layer Data Source
	//IBOutlet LayerDataSource *dataSource;
	
	/// The unique ID for layer
	NSInteger uniqueLayerID;
	
	/// The unique ID for floating layer
	NSInteger uniqueFloatingLayerID;
	
	/// The unique ID for this document (sometimes used)
	NSInteger uniqueDocID;
	
	/// The document's measure style
	SeaUnits measureStyle;
	
	/// Is the document locked?
	BOOL locked;
	
	/// Is the document initing from the pasteboard or plug-in?
	int specialStart;
	
	// File types with Cocoa can be difficult
	BOOL restoreOldType;
	NSString *oldType;
	
	/// Is the file the current version?
	BOOL current;
}

/*!
	@property	contents
	@discussion	The contents of the document (a subclass of <code>SeaContent</code>)
 */
@property (strong, readonly) __kindof SeaContent *contents;

/*!
	@property	measureStyle
	@discussion	The document's measure style
 */
@property (setter = changeMeasuringStyle:) SeaUnits measureStyle;

/// The whiteboard that represents this document
@property (strong) SeaWhiteboard *whiteboard;

// CREATION METHODS

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		initWithPasteboard
	@discussion	Initializes an instance of this class with a single pasteboard
				layer.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)initWithPasteboard;

/*!
	@method		initWithData:type:width:height:
	@discussion	Initializes an instance of this class with the given data.
	@param		data
				The data with which this class is being initialized.
	@param		type
				The type with which this class is being initialized.
	@param		width
				The width of the data with which this class is being initialized.
	@param		height
				The height of the data with which this class is being initialized.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)initWithData:(unsigned char *)data type:(XcfImageType)type width:(int)width height:(int)height;

/*!
	@method		saveDocument:
	@discussion Called to save a document (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocument:(nullable id)sender;

/*!
	@method		saveDocumentAs:
	@discussion Called to save a document as (makes current).
	@param		sender
				Ignored.
*/
- (IBAction)saveDocumentAs:(nullable id)sender;

// GATEWAY METHODS

/*!
	@method		contents
	@discussion	Returns the contents of the document.
	@result		Returns an instance of <code>SeaContent</code>.
*/
- (__kindof SeaContent*)contents;

/*!
	@property	selection
	@discussion	Returns the selection manager of the document.
	@result		Returns an instance of <code>SeaSelection</code>.
*/
@property (readonly, strong) SeaSelection *selection;

/*!
	@property	operations
	@discussion	The operations manager for this document.
*/
@property (weak) IBOutlet SeaOperations *operations;

/*!
	@property	tools
	@brief		The tools for this document.
	@discussion	Returns the tools manager of the document.
	@result		Returns an instance of <code>SeaTools</code>.
*/
@property (weak) IBOutlet SeaTools *tools;

/*!
	@property	helpers
	@brief		An outlet to the helpers of this document
	@discussion	Returns an object containing various helper methods for the
				document.
	@result		Returns an instance of <code>SeaHelpers</code<.
*/
@property (weak) IBOutlet SeaHelpers *helpers;

/*!
	@property	warnings
	@brief		An outlet to the warnings utility for this document
	@discussion	Returns an object contaning the warning related methods.
	@result		Returns an instance of <code>WarningsUtility</code>.
*/
@property (weak) IBOutlet WarningsUtility *warnings;

/*!
	@property	pluginData
	@brief		The plug-in data used by this document
	@discussion	Returns the object shared between Seashore and most plug-ins.
	@result		Returns an instance of <code>PluginData</code>.
*/
@property (weak) IBOutlet PluginData *pluginData;

/*!
	@property	docView
	@discussion	Returns the document view of the document.
	@result		Returns an instance of SeaView.
*/
@property (readonly, retain) SeaView *docView;

/*!
	@method		window
	@discussion	Returns the window of the document.
	@result		Returns an instance of NSWindow.
*/
- (NSWindow*)window;

/*!
	@method		updateWindowColor
	@discussion	Updates the color of the window background
*/
- (void)updateWindowColor;

/*!
	@property	textureExporter
	@brief		The special texture exporter
	@discussion	Returns the texture exporter.
	@result		Returns an instance of <code>TextureExporter</code>.
*/
@property (weak) IBOutlet TextureExporter *textureExporter;

/*!
 @property      brushExporter
 @discussion    Returns the brush exporter.
 @result        Returns an instance of BrushExporter.
 */
@property (weak) IBOutlet BrushExporter *brushExporter;

// DOCUMENT METHODS

/*!
	@method		readFromURL:ofType:error:
	@discussion	Reads a given file from disk.
	@param		path
				The file URL to be read.
	@param		type
				The type of the file to be read.
	@result		Returns \c YES if the file is successfully read, \c NO otherwise.
*/
- (BOOL)readFromURL:(NSURL *)path ofType:(NSString *)type error:(NSError * __autoreleasing *)outError;

/*!
	@method		writeToURL:ofType:error:
	@discussion	Writes the document's data to disk.
	@param		filename
				The file URL that the data should be written to.
	@param		ignore
				The type of the file that the data that should be written to.
	@result		Returns \c YES if the file is successfully written, \c NO otherwise.
*/
- (BOOL)writeToURL:(NSURL *)filename ofType:(NSString *)ignore error:(NSError * __autoreleasing *)outError;

/*!
	@method		printShowingPrintPanel:
	@discussion	Prints the document, showing the print panel if requested.
	@param		showPanels
				YES if the method should show the associated print panels, NO
				otherwise.
*/
- (void)printShowingPrintPanel:(BOOL)showPanels;

/*!
	@method		prepareSavePanel:
	@discussion	Customizes the save panel, adding a pop-up menu through which
				the user can select a particular exporter.
	@param		savePanel
				The save panel to be adjusted.
	@result		Returns YES if the adjustment was successful, NO otherwise.
*/
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;

/*!
	@method		showExporterOptions:
	@discussion	Displays the options for the currently selected exporter.
	@param		sender
				Ignored.
*/
- (IBAction)showExporterOptions:(id)sender;

/*!
	@method		exporterChange:
	@discussion	Changes the active exporter for the document based upon the
				selection of the exportersPopUp.
	@param		sender
				Ignored.
*/
- (IBAction)exporterChanged:(id)sender;

// DOCUMENT EVENT METHODS

/*!
	@method 	close
	@discussion	Called to close the document.
*/
- (void)close;

/*!
	@method		windowDidBecomeMain:
	@discussion	Called when a sheet is shown.
	@param		notification
				Ignored.
*/
- (void)windowWillBeginSheet:(NSNotification *)notification;

/*!
	@method		windowDidEndSheet:
	@discussion	Called after a sheet is closed.
	@param		notification
				Ignored.
*/
- (void)windowDidEndSheet:(NSNotification *)notification;

/*!
	@method		windowDidBecomeMain:
	@discussion	Called when the document is activated.
	@param		notification
				Ignored.
*/
- (void)windowDidBecomeMain:(NSNotification *)notification;

/*!
	@method		windowDidResignMain:
	@discussion	Called when the document loses focus.
	@param		notification
				Ignored.
*/
- (void)windowDidResignMain:(NSNotification *)notification;

/*!
	@method		windowDidResignKey:
	@discussion	Called when the document loses key focus.
	@param		aNotification
				Ignored.
*/
- (void)windowDidResignKey:(NSNotification *)aNotification;

/*!
	@method		windowWillUseStandardFrame:defaultFrame:
	@discussion	Called when the document wants to zoom.
	@param		sender
				The window zooming
	@param		defaultFrame
				Ignored
	@result		Returns the new frame of the window
*/
- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame;

/*!
	@method		standardFrame
	@discussion	For calculating the preferred size of the window.
	@result		Returns the rect of the new frame.
*/
- (NSRect) standardFrame;

// EXTRA METHODS

/*!
	@method		current
	@discussion	Returns a boolean indicating whether the document is current.
				Documents are not current, if they were created using the "Compare
				to Last Saved" menu item and have not been resaved since.
	@result		Returns YES if the document is original, NO otherwise.
*/
- (BOOL)current;

/*!
	@method		setCurrent
	@discussion	Sets the current boolean to the specified value. Remember non-current
				documents will be deleted upon closing!
*/
- (void)setCurrent:(BOOL)value;

/*!
	@oroperty	current
	@discussion	A boolean indicating whether the document is current.
				Documents are not current, if they were created using the "Compare
				to Last Saved" menu item and have not been resaved since.
 */
@property BOOL current;

/*!
	@property	uniqueLayerID
	@discussion	Returns a unique ID for a given layer and then increments the
				uniqueLayerID instance variable so the next layer will recieve a
				unique ID. To ensure sequential numbering this method should
				only be called once by the intializer of SeaLayer and its result
				stored.
	@result		Returns an integer representing a new layer may assign to
				itself.
*/
@property (readonly) NSInteger uniqueLayerID;

/*!
	@property	uniqueFloatingLayerID
	@discussion	Returns a unique ID for a given floating layer and then
				increments the uniqueFloatingLayerID instance variable so the
				next floating layer will recieve a unique ID. To ensure
				sequential numbering this method should only be called once by
				the intializer of SeaFloatingLayer and its result stored.
	@result		Returns an integer representing a new layer may assign to
				itself.
*/
@property (readonly) NSInteger uniqueFloatingLayerID;

/*!
	@property	uniqueDocID
	@discussion	Returns the unique ID of the document.
	@result		Returns an integer representing a unique ID for the document.
*/
@property (readonly) NSInteger uniqueDocID;

/*!
	@method		windowNibName
	@discussion	Returns the name of the NIB file associated with this document's
				window for use by NSDocumentController.
	@result		Returns an NSString representing the name of the NIB file.
*/
- (NSString *)windowNibName;

// MENU RELATED

/*!
	@method		customUndo:
	@param		sender
				Ignored.
	@discussion	Undoes the last change.
*/
- (IBAction)customUndo:(id)sender;

/*!
	@method		customRedo:
	@param		sender
				Ignored.
	@discussion	Redoes the last change.
*/
- (IBAction)customRedo:(id)sender;

/*!
	@method		changeMeasuringStyle:
	@discussion	Changes the measuring style of the document.
	@param		aStyle
				An integer representing the measuring style (see
				Units.h).
*/
- (void)changeMeasuringStyle:(SeaUnits)aStyle;

/*!
	@method		measureStyle
	@discussion	Returns the measuring style.
	@result		Returns an integer representing the measuring style (see
				Units.h).
*/
- (SeaUnits)measureStyle;

/*!
	@method		locked
	@discussion	Returns whether or not the document is locked. The document can
				be locked as a consequence of a call to lock or as a consequence
				of a sheet being open in the documents window.
	@result		Returns YES if the document is locked, NO otherwise.
*/
- (BOOL)locked;

/*!
	@method		lock
	@discussion	Locks the document (regardless of how many calls were previously
				made to unlock). When the document is locked the user is
				prevented from making certain changes to the document (i.e.
				undoing things, removing layers, etc.). Locking is an internal
				temporary state and as such should be used when drawing or
				changing the margins of the document not to prevent users from
				changing a read-only file.
*/
- (void)lock;

/*!
	@method		unlock
	@discussion	Unlocks the document (regardless of how many calls were
				previously made to lock). When the document is locked the user
				is prevented from making certain changes to the document (i.e.
				undoing things, removing layers, etc.). Locking is an internal
				temporary state and as such should be used when drawing or
				changing the margins of the document not to prevent users from
				changing a read-only file.
*/
- (void)unlock;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
	@method		runModalSavePanelForSaveOperation:delegate:didSaveSelector:contextInfo:
	@discussion	Runs the save panel for the given save operation.
	@param		saveOperation
				The save operation.
	@param		delegate
				The save panel's delegate.
	@param		didSaveSelector
				The callback selector once the save panel is complete.
	@param		contextInfo
				The pointer to pass to the callback method.
*/
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(nullable id)delegate didSaveSelector:(nullable SEL)didSaveSelector contextInfo:(nullable void *)contextInfo;

/*!
	@method		document:didSave:contextInfo:
	@param		doc
				The document being saved.
	@param		didSave
				Whether the document was saved.
	@param		contextInfo
				A pointer to pass to the callback method.
*/
- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo;

/*!
	@method		fileTypeFromLastRunSavePanel
	@discussion	Must be overridden to make sure the saving of files works
				correctly.
	@result		Returns exactly the same as the "fileType" method would.
*/
- (NSString *)fileTypeFromLastRunSavePanel;

/*!
    @method     scrollView
	@result		Returns the document main view as a scroll view
*/

- (NSScrollView *)scrollView;

/*!
	@property	dataSource
	@result		Returns the data source used by the layers view
*/
@property (weak) IBOutlet LayerDataSource *dataSource;

@end

NS_ASSUME_NONNULL_END
