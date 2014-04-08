//
//  SSKPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import <Foundation/Foundation.h>
#import <SeashoreKit/SeaPlugins.h>

@interface SSKPlugin : NSObject
{
	@protected
	// YES if the application succeeded
	BOOL success;
	
	// Determines the boundaries of the layer
	CGRect bounds;
	
	// Signals whether the bounds rectangle is valid
	BOOL boundsValid;
}
@property (weak) SeaPlugins *seaPlugins;

- (void)savePluginPreferences;

- (instancetype)initWithManager:(SeaPlugins *)manager;

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
 * @method		validateMenuItem:
 * @discussion	Determines whether a given menu item should be enabled or
 *				disabled.
 * @param		menuItem
 *					The menu item to be validated.
 * @result		YES if the menu item should be enabled, NO otherwise.
 */
- (BOOL)validateMenuItem:(id)menuItem;

/*!
 * @method		determineContentBorders
 * @discussion	Determines the content borders, must be called before executing.
 * @param		pluginData
 *					The PluginData object.
 */
- (void)determineContentBorders:(PluginData *)pluginData;

@end
