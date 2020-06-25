#import <Foundation/Foundation.h>
#import <AppKit/NSMenu.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#import "SeaDocument.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"
#import "SSKTerminatable.h"
#else
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/SeaDocument.h>
#import <SeashoreKit/PluginData.h>
#import <SeashoreKit/SeaWhiteboard.h>
#import <SeashoreKit/SSKTerminatable.h>
#endif

@class SeaPlugins;
@class PluginData;
@class SeaController;

NS_ASSUME_NONNULL_BEGIN

/*!
 @enum		k...Plugin
 @constant	kBasicPlugin
 Specifies a basic effects plug-in.
 @constant	kPointPlugin
 Specifies a basic effect plug-in that acts on one or
 more point given to it by the effects tool.
 */
typedef NS_ENUM(int, SeaPluginType) {
	//! Specifies a basic effects plug-in.
	SeaPluginBasic = 0,
	//! Specifies a basic effect plug-in that acts on one or
	//! more point given to it by the effects tool.
	SeaPluginPoint = 1
};

/*!
	@protocol	SeaPluginClass
	@abstract	A basic class from which to build plug-ins.
	@discussion	This class is in the public domain allowing plug-ins of any
				license to be made compatible with Seashore.
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/
@protocol SeaPluginClass <NSObject, NSMenuItemValidation>

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
				The SeaPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or \c NULL otherwise).
*/
- (instancetype)initWithManager:(SeaPlugins *)manager;

/*!
	@property	type
	@discussion	Returns the type of plug-in so Seashore can correctly interact
				with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
@property (readonly) SeaPluginType type;

@optional
/*!
	@property	points
	@discussion	Returns the number of points that the plug-in requires from the
				effect tool to operate.
	@result		Returns an integer indicating the number of points the plug-in
				requires to operate.
*/
@property (readonly) int points;

@required
/*!
	@property	name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
*/
@property (readonly, copy) NSString *name;

/*!
	@property	groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
*/
@property (readonly, copy) NSString *groupName;

@optional
/*!
	@property	instruction
	@discussion	Returns the plug-in's instructions.
	@result		Returns a NSString indicating the plug-in's instructions
				(127 chars max).
*/
@property (readonly, copy) NSString *instruction;

@required
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
	@property	canReapply
	@discussion Returns whether or not the plug-in can be applied again.
	@result		Returns YES if the plug-in can be applied again, NO otherwise.
*/
@property (readonly) BOOL canReapply;

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@optional

/*!
	@property	sanity
	@discussion	Returns a string to indicate this is a Seashore plug-in.
	@result		Returns the NSString "Seashore Approved (Bobo)".
*/
@property (readonly, copy) NSString *sanity;

@end

/*!
	@class		SeaPlugins
	@abstract	Manages all of Seashore's plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain<br>
				<b>Copyright:</b> N/A
*/
@interface SeaPlugins : NSObject <SSKTerminatable> {

	/// The SeaController object
	IBOutlet SeaController *controller;

	/// An array of all Seahore's plug-ins
	NSMutableArray<id<SeaPluginClass>> *plugins;

	/// The plug-ins used by the effect tool
	NSArray<id<SeaPluginClass>> *pointPlugins;

	/// The names of the plug-ins used by the effect tool
	NSArray<NSString*> *pointPluginsNames;

	/// The submenu to add plug-ins to
	IBOutlet NSMenu *effectMenu;
	
	/// The last effect applied
	NSInteger lastEffect;
	
	/// Stores the index of the "CIAffineTransform" plug-in - this plug-in handles Seashore CoreImage manipulation
	NSInteger ciAffineTransformIndex;
	
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (instancetype)init;

/*!
	@method		terminate
	@discussion	Saves preferences to disk (this method is called before the
				application exits by the SeaController).
*/
- (void)terminate;


/*!
	@property	affinePlugin
	@discussion	Returns the plug-in to be used for Core Image affine transforms.
	@result		Returns an instance of the plug-in to be used  for Core Image
				affine transforms or \c nil if no such instance exists.
*/
@property (readonly, retain, nullable) id<SeaPluginClass> affinePlugin;

/*!
	@property	data
	@discussion	Returns the address of a record shared between Seashore and the
				plug-in.
	@result		Returns the address of a record shared between Seashore and the
				plug-in.
*/
@property (readonly, strong) PluginData *data;

/*!
	@method		run:
	@discussion	Runs the plug-in specified by the sender.
	@param		sender
				The menu item for the plug-in.
*/
- (IBAction)run:(nullable id)sender;

/*!
	@method		reapplyEffect
	@discussion	Reapplies the last effect without configuration.
	@param		sender
				Ignored.
*/
- (IBAction)reapplyEffect:(nullable id)sender;

/*!
	@method		cancelReapply
	@discussion	Prevents reapplication of the last effect.
*/
- (void)cancelReapply;

/*!
	@property	hasLastEffect
	@discussion	Returns whether there is a last effect.
	@result		Returns YES if there is a last effect, NO otherwise.
*/
@property (readonly) BOOL hasLastEffect;

/*!
	@property	pointPluginsNames
	@discussion	Returns the names of the point plugins.
	@result		Returns an NSArray.
*/
@property (readonly, copy) NSArray<NSString*> *pointPluginsNames;

/*!
	@property	pointPlugins
	@discussion	Returns the point plugins.
	@result		Returns an NSArray.
*/
@property (readonly, copy) NSArray<id <SeaPluginClass>> *pointPlugins;


/*!
	@property	activePointEffect
	@discussion	Returns the presently active plug-in according to
				the effect table.
	@result		Returns an instance of the plug-in's class.
*/
@property (readonly, nullable) id<SeaPluginClass> activePointEffect;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		\c YES if the menu item should be enabled, \c NO otherwise.
*/
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@end

//! Specifies a basic effects plug-in.
static const SeaPluginType kBasicPlugin NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPluginBasic", 10.2, 10.8)  = SeaPluginBasic;
//! Specifies a basic effect plug-in that acts on one or
//! more point given to it by the effects tool.
static const SeaPluginType kPointPlugin NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaPluginPoint", 10.2, 10.8) = SeaPluginPoint;

NS_ASSUME_NONNULL_END
