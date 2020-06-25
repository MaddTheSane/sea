/*!
	@header		CIBumpClass
	@abstract	Applies a bump at the specified point.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SeaPlugins.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"
#import "SSKCIPlugin.h"

@interface CIBumpClass : SSKCIPlugin

/// The scale of the bump
@property CGFloat scale;

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact
				with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
- (SeaPluginType)type;

/*!
	@method		points
	@discussion	Returns the number of points that the plug-in requires from the
				effect tool to operate.
	@result		Returns an integer indicating the number of points the plug-in
				requires to operate.
*/
- (int)points;

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
	@method		instruction
	@discussion	Returns the plug-in's instructions.
	@result		Returns a NSString indicating the plug-in's instructions
				(127 chars max).
*/
- (NSString *)instruction;

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
	@method		preview:
	@discussion	Previews the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)preview:(id)sender;

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

@end
