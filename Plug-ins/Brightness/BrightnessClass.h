/*!
	@header		BrightnessClass
	@abstract	Adjusts the brightness and contrast of the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2004 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#import "SeaPlugins.h"
#import "SSKCIPlugin.h"

@interface BrightnessClass : SSKVisualPlugin
//! The brightness
@property CGFloat brightness;

//! The contrast
@property CGFloat contrast;

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
	@method		preview:
	@discussion	Previews the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)preview:(id)sender;

/*!
	@method		adjust
	@discussion	Executes the adjustments.
*/
- (void)adjust;

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
