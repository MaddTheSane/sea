/*!
	@header		TexturizeClass
	@abstract	Generate a texture from the active document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b>
				Copyright (c) 2004-2005 Manu Cornet and Jean-Baptise Rouquier
*/

#import <Cocoa/Cocoa.h>
#import <SeashoreKit/SeaPlugins.h>

@interface TexturizeClass : NSObject <SeaPluginClass> {

	// The plug-in's manager
	__unsafe_unretained SeaPlugins *seaPlugins;

	// The label displaying the overlap
	IBOutlet NSTextField *overlapLabel;
	
	// The slider for the overlap
	IBOutlet NSSlider *overlapSlider;

	// The label displaying the width
	IBOutlet NSTextField *widthLabel;
	
	// The slider for the width
	IBOutlet NSSlider *widthSlider;
	
	// The label displaying the height
	IBOutlet NSTextField *heightLabel;
	
	// The slider for the height
	IBOutlet NSSlider *heightSlider;
	
	// The checkbox indicating whether the resulting texture should be tileable
	IBOutlet NSButton *tileableCheckbox;
	
	// The panel for the plug-in
	IBOutlet NSPanel *panel;
	
	// The progress bar to indicate progress
	IBOutlet NSProgressIndicator *progressBar;

	// The overlap
	CGFloat overlap;
	
	// The width
	CGFloat width;
	
	// The height
	CGFloat height;
	
	// Should the resulting texture be tileable?
	BOOL tileable;

	// YES if the application succeeded
	BOOL success;
}

/// The overlap
@property (nonatomic) CGFloat overlap;
/// The width
@property (nonatomic) CGFloat width;
/// The height
@property (nonatomic) CGFloat height;
/// Should the resulting texture be tileable?
@property (nonatomic, getter=isTileable) BOOL tileable;

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
				The SeaPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)initWithManager:(SeaPlugins *)manager;

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact
				with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
- (int)type;

/*!
	@method		name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
*/
- (NSString *)name;

/*!
	@method		groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
*/
- (NSString *)groupName;

/*!
	@method		sanity
	@discussion	Returns a string to indicate this is a Seashore plug-in.
	@result		Returns the NSString "Seashore Approved (Bobo)".
*/
- (NSString *)sanity;

/*!
	@method		run
	@discussion	Runs the plug-in.
*/
- (void)run;

/*!
	@method		apply:
	@discussion	Applies the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		reapply
	@discussion	Applies the plug-in with previous settings.
*/
- (void)reapply;

/*!
	@method		canReapply
	@discussion Returns whether or not the plug-in can be applied again.
	@result		Returns YES if the plug-in can be applied again, NO otherwise.
*/
- (BOOL)canReapply;

/*!
	@method		cancel:
	@discussion	Cancels the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		update:
	@discussion	Updates the panel's labels.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		texturize
	@discussion	Executes the texturize.
*/
- (void)texturize;

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
