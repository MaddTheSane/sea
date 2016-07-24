#import "Globals.h"

/*!
	@enum		kPegasusUpdate...
	@constant	kPegasusUpdateAll
				Indicates that all aspects of the Pegasus utility should be updated.
	@constant	kPegasusUpdateLayerView
				Indicates that only the layer view of the Pegasus utility should be updated.
*/
NS_ENUM(int) {
	kPegasusUpdateAll,
	kPegasusUpdateLayerView
};

/*!
	@defined	kMaxPixelsForLiveUpdate
	@discussion	Defines the maximum number of pixels in a layer before Seashore
				will stop updating its opacity in a live manner.
*/
#define kMaxPixelsForLiveUpdate 262144

@class LayerSettings;
@class SeaDocument;
@class LayerDataSource;
@class ColorSelectView;

/*!
	@class		PegasusUtility
	@abstract	Handles layers, channels and paths.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@interface PegasusUtility : NSObject {
	
	// The LayersView which appears in this utility
	IBOutlet id layersView;
	
	// The panel responsible for layer settings
	IBOutlet id layerSettingsPanel;
	
	// The colour select view (this needs to be updated when the channel is changed on an RGBA image)
	IBOutlet ColorSelectView *colorSelectView;
	
	// The various layer buttons
	IBOutlet NSButton *newButton;
	IBOutlet NSButton *duplicateButton;
	IBOutlet NSButton *upButton;
	IBOutlet NSButton *downButton;
	IBOutlet NSButton *deleteButton;
	
	// The document which is the focus of this utility
	IBOutlet SeaDocument *document;
	
	// Whether or not the utility is enabled
	BOOL enabled;

	// The Data Source used by the table that serves as the layers view.
	IBOutlet LayerDataSource *dataSource;
}

/*!
	@method		activate
	@discussion	Activates this utility with it's document.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates this utility.
*/
- (void)deactivate;

/*!
	@method		update:
	@discussion	Updates the utility.
	@param		updateCode
				A Pegasus update code indicating the part of the utility to
				update.
*/
- (void)update:(int)updateCode;

/*!
	@method		layerSettings
	@discussion	Returns the layer settings manager associated with this object.
	@result		Returns an instance of LayerSettings representing the layer
				settings manager associated with this object.
*/
- (LayerSettings*)layerSettings;

/// The object for handling layer settings
@property (weak) IBOutlet LayerSettings* layerSettings;

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
	@method		setEnabled:
	@discussion	Enables or disables the utility.
	@param		value
				YES if the utility should be enabled, NO otherwise.
*/
- (void)setEnabled:(BOOL)value;

/// Whether or not the utility is enabled
@property (nonatomic, getter=isEnabled) BOOL enabled;

/*!
	@method		toggleLayers:
	@discussion	Toggles the visibility of the of the "Layers" tab of the Pegasus
				utility.
	@param		sender
				Ignored.
*/
- (IBAction)toggleLayers:(id)sender;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled and choses the correct menu item title for it if
				appropriate).
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

/*!
	@property	visible
	@discussion	Returns whether or not the utility's window is visible.
	@result		Returns YES if the utility's window is visible, NO otherwise.
*/
@property (readonly) BOOL visible;

// Proxy Actions
/*!
	@method		addLayer:
	@discussion	Adds a new layer to the document.
	@param		sender
				Ignored
*/
- (IBAction)addLayer:(id)sender;

/*!
	@method		duplicateLayer:
	@discussion	Duplicates the current layer in the document.
	@param		sender
				Ignored
*/
- (IBAction)duplicateLayer:(id)sender;

/*!
	@method		deleteLayer:
	@discussion	Deletes the currently selected layer in the document.
	@param		sender
				Ignored
 */
- (IBAction)deleteLayer:(id)sender;

@end
