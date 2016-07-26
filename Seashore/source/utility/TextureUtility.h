#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "AbstractPanelUtility.h"

@class SeaTexture;
@class SeaDocument;
@class SeaProxy;

/*!
	@class		TextureUtility
	@abstract	Loads and manages all textures for the user.
	@discussion	This class is based upon the BrushUtility class.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/
@interface TextureUtility : AbstractPanelUtility {
	// The proxy object
	IBOutlet SeaProxy *seaProxy;
	
	// The texture grouping pop-up
    IBOutlet NSPopUpButton *textureGroupPopUp;
	
	// The label that presents the user with the texture name
	IBOutlet NSTextField *textureNameLabel;
	
	// The view that displays the textures
    IBOutlet id view;
    	
	// The opacity selection items
	IBOutlet NSSlider *opacitySlider;
	IBOutlet NSTextField *opacityLabel;
	
	// The document which is the focus of this utility
	IBOutlet SeaDocument *document;
	
	// An dictionary of all brushes known to Seashore
	NSDictionary *textures;
	
	// An array of all groups (an array of an array SeaTexture's) and group names (an array of NSString's)
	NSArray<NSArray<SeaTexture*>*> *groups;
	NSArray<NSString*> *groupNames;
	
	// The index of the currently active group
	NSInteger activeGroupIndex;
	
	// The index of the currently active texture
	NSInteger activeTextureIndex;
	
	// The opacity value to be used with the texture
	int opacity;
	
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		activate:
	@discussion	Activates this utility with the given document.
	@param		sender
				The document to activate the utility with.
*/
- (void)activate:(id)sender;

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
	@method		loadTextures:
	@discussion	Frees (if necessary) and then reloads all the textures from
				Seashore's textures directory.
	@param		update
				YES if the texture utility should be updated after reloading all
				the textures (typical case), NO otherwise.
*/
- (void)loadTextures:(BOOL)update;

/*!
	@method		addTextureFromPath:toGroup:
	@discussion	Loads a texture from the given path (handles updates).
	@param		path
				The path from which to load the texture.
*/
- (void)addTextureFromPath:(NSString *)path;

/*!	
	@method		changeOpacity:
	@discussion	Called after the opacity is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeOpacity:(id)sender;

/*!
	@method		changeGroup:
	@discussion	Called when the texture group is changed.
	@param		sender
				Ignored.
*/
- (IBAction)changeGroup:(id)sender;

/*!
	@property	opacity
	@discussion	Returns the opacity to be used by the active texture.
	@result		Reutrns an integer from 0 to 255 indicating the opacity to be
				used by the active texture. The texture is fully opaque if the
				opacity is 255.
*/
@property (readonly) int opacity;

/*!
	@method		activeTexture
	@discussion	Returns the currently active texture.
	@result		Returns an instance of SeaTexture representing the currently
				active texture.
*/
- (SeaTexture*)activeTexture;

/*!
	@property	activeTextureIndex
	@discussion	Returns the index of the currently active texture.
	@result		Returns an integer representing the index of the currently
				active texture.
*/
@property (readonly) NSInteger activeTextureIndex;

/*!
	@method		setActiveTextureIndex:
	@discussion	Sets the active texture to that specified by the given index.
	@param		index
				The index of the texture to activate.
*/
- (void)setActiveTextureIndex:(NSInteger)index;

/*!
	@method		textures
	@discussion	Returns all the textures in the currently active group.
	@result		Returns an array with all the textures in the currently active
				group. 
*/
- (NSArray<SeaTexture*> *)textures;

/*!
	@method		groupNames
	@discussion	Returns the textures' group names (excluding custom groups).
	@result		Returns an NSArray containing the textures' group names.
*/
- (NSArray<NSString*> *)groupNames;

@end
