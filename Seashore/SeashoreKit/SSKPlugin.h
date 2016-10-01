//
//  SSKPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import <Foundation/Foundation.h>
#import <SeashoreKit/SeaPlugins.h>
#import <SeashoreKit/PluginClass.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSKPlugin : NSObject <SeaPluginClass>
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

@property BOOL success;

- (void)savePluginPreferences;

/*!
 @method		initWithManager:
 @discussion	Initializes an instance of this class with the given manager.
 @param		manager
 The SeaPlugins instance responsible for managing the plug-ins.
 @result		Returns instance upon success (or NULL otherwise).
 */
- (instancetype)initWithManager:(SeaPlugins *)manager;

/*!
 @property		type
 @discussion	Returns the type of plug-in so Seashore can correctly interact with the plug-in.
 @result		Returns an integer indicating the plug-in's type.
 */
@property (readonly) int type;

/*!
 @property		name
 @discussion	Returns the plug-in's name.
 @result		Returns an NSString indicating the plug-in's name.
 */
@property (readonly, copy) NSString *name;

/*!
 @property		groupName
 @discussion	Returns the plug-in's group name.
 @result		Returns an NSString indicating the plug-in's group name.
 */
@property (readonly, copy) NSString *groupName;

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
 @property		canReapply
 @discussion	Returns whether or not the plug-in can be applied again.
 @result		Returns YES if the plug-in can be applied again, NO otherwise.
 */
@property (readonly) BOOL canReapply;

/*!
 * @method		validateMenuItem:
 * @discussion	Determines whether a given menu item should be enabled or
 *				disabled.
 * @param		menuItem
 *					The menu item to be validated.
 * @result		YES if the menu item should be enabled, NO otherwise.
 */
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem NS_SWIFT_NAME(validateMenuItem(_:));

/*!
 * @method		determineContentBorders
 * @discussion	Determines the content borders, must be called before executing.
 * @param		pluginData
 *				The PluginData object.
 */
- (void)determineContentBorders:(PluginData *)pluginData;

@end

NS_ASSUME_NONNULL_END
