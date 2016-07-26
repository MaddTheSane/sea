#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
	@enum		k...Modifier
	@constant	kNoModifier
				Indicates no modifier.
	@constant	kAltModifier
				Indicates an option key modifier.
	@constant	kShiftModifier
				Indicates an shift key modifier.
	@constant	kControlModifier
				Indicates a control key modifier.
	@constant	kShiftControlModifier
				Indicates a shift-control key modifier.
	@constant	kAltControlModifier
				Indicates a option-control key modifier.
	@constant	kReservedModifier1
				Indicates a reserved modifier (no shortcut key).
	@constant	kReservedModifier2
				Indicates a reserved modifier (no shortcut key).
*/
typedef NS_ENUM(NSInteger, AbstractModifiers) {
	//! Indicates no modifier.
	AbstractModifierNone = 0,
	//! Indicates an option key modifier.
	AbstractModifierAlt = 1,
	//! Indicates a shift key modifier.
	AbstractModifierShift = 2,
	//! Indicates a control key modifier.
	AbstractModifierControl = 3,
	//! Indicates a shift-control key modifier.
	AbstractModifierShiftControl = 4,
	//! Indicates a option-control key modifier.
	AbstractModifierAltControl = 5,
	//! Indicates a reserved modifier (no shortcut key).
	AbstractModifierReserved1 = 20,
	//! Indicates a reserved modifier (no shortcut key).
	AbstractModifierReserved2 = 21,
	
	kNoModifier NS_SWIFT_UNAVAILABLE("Use .None instead") = AbstractModifierNone,
	kAltModifier NS_SWIFT_UNAVAILABLE("Use .Alt instead") = AbstractModifierAlt,
	kShiftModifier NS_SWIFT_UNAVAILABLE("Use .Shift instead") = AbstractModifierShift,
	kControlModifier NS_SWIFT_UNAVAILABLE("Use .Control instead") = AbstractModifierControl,
	kShiftControlModifier NS_SWIFT_UNAVAILABLE("Use .ShiftControl instead") = AbstractModifierShiftControl,
	kAltControlModifier NS_SWIFT_UNAVAILABLE("Use .AltControl instead") = AbstractModifierAltControl,
	kReservedModifier1 NS_SWIFT_UNAVAILABLE("Use .Reserved1 instead") = AbstractModifierReserved1,
	kReservedModifier2 NS_SWIFT_UNAVAILABLE("Use .Reserved2 instead") = AbstractModifierReserved2,
};

@class SeaDocument;

/*		
	@class		AbstractOptions
	@abstract	Acts as a base class for the options panes of all tools.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface AbstractOptions : NSObject {
	/// The options view associated with this tool
    IBOutlet NSView *view;
	
	/// The modifier options associated with this tool
	IBOutlet NSPopUpButton *modifierPopup;
	
	/// The document associated
	SeaDocument *document;
}

/*!
	@method		activate:
	@discussion	Activates the options panel with the given document.
	@param		sender
				The document to activate the options panel with.
*/
- (void)activate:(id)sender;

/*!
	@method		update
	@discussion	Updates the options panel.
*/
- (void)update;

/*!
	@method		forceAlt
	@discussion	Forces the option modifier in special circumstances.
*/
- (void)forceAlt;

/*!
	@method		unforceAlt
	@discussion	Unforces the option modifier only if it was previously forced.
*/
- (void)unforceAlt;

/*!
	@method		updateModifiers:
	@discussion	Updates the modifier pop-up.
	@param		modifiers
				An unsigned int representing the new modifiers.
*/
- (void)updateModifiers:(NSEventModifierFlags)modifiers;

/*!
	@method		modifier
	@discussion	Returns an indication of the modifier.
	@result		Returns an integer indicating the active modifier's tag.
*/
- (AbstractModifiers)modifier;


/*!
	@method		modifierPopupChanged:
	@discussion	Called when the popup is changed.
	@param		sender
				Needs to be the popup menu.
*/
- (IBAction)modifierPopupChanged:(id)sender;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns NO to indicate that by defualt tools do not use
				textures.
*/
- (BOOL)useTextures;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

/*!
	@method		view
	@discussion	Returns the option's view
	@result		Returns the option's view
*/
- (NSView *)view;

@end
