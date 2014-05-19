/*!
	@header		CIWhitePointAdjustClass
	@abstract	Adjusts the white point of the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <ApplicationServices/ApplicationServices.h>
#import "SeaPlugins.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"
#import "SSKPlugin.h"

@interface CIWhitePointAdjustClass : SSKPlugin
{
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
	NSBitmapImageRep *temp_rep;
}

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact with the plug-in.
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
	@method		execute
	@discussion	Executes the effect.
*/
- (void)execute;

/*!
	@method		executeGrey
	@discussion	Executes the effect for greyscale images.
	@param		pluginData
				The PluginData object.
*/
- (void)executeGrey:(PluginData *)pluginData;

/*!
	@method		executeGrey
	@discussion	Executes the effect for colour images.
	@param		pluginData
				The PluginData object.
*/
- (void)executeColor:(PluginData *)pluginData;

/*!
	@method		executeChannel:withBitmap:
	@discussion	Executes the effect with any necessary changes depending on channel selection
				(called by either executeGrey or executeColor). 
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		whitePointAdjust:withBitmap:
	@discussion	Called by execute once preparation is complete.
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)whitePointAdjust:(PluginData *)pluginData withBitmap:(unsigned char *)data;

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
