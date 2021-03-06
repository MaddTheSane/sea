/*!
	@header		CIDisplacementDistortionClass
	@abstract	Crystallize the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				Default texture from Apple with permission to use "without restriction"
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SeaPlugins.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"
#import "SSKCIPlugin.h"

@interface CIDisplacementDistortionClass : SSKCIPlugin <NSOpenSavePanelDelegate>
{
	// The path of the texture to be used
	NSString *texturePath;
}
//! The label displaying the current texture
@property (weak) IBOutlet NSTextField *textureLabel;

//! The path of the texture to be used
@property (copy) NSString *texturePath;

//! The scale of the crystallize
@property NSInteger scale;

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
- (SeaPluginType)type;

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
	@method		selectTexture:
	@discussion	Selects the texture to be used for glass distortion.
	@param		sender
				Ignored.
*/
- (IBAction)selectTexture:(id)sender;

@end
