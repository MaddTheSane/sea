#import <Cocoa/Cocoa.h>
#import "Globals.h"

/*!
	@enum		SeaAspectType
	@constant	kNoAspectType
				Indicates no specification.
	@constant	kRatioAspectType
				Indicates ratio specification.
	@constant	kExactPixelAspectType
				Indicates exact specification in pixels.
	@constant	kExactInchAspectType
				Indicates exact specification in inches.
	@constant	kExactMillimeterAspectType
				Indicates exact specification in millimetres.
*/
typedef NS_ENUM(NSInteger, SeaAspectType) {
	//! Indicates no specification.
	SeaAspectTypeNone = -2,
	//! Indicates ratio specification.
	SeaAspectTypeRatio = -1,
	//! Indicates exact specification in pixels.
	SeaAspectTypeExactPixel = 0,
	//! Indicates exact specification in inches.
	SeaAspectTypeExactInch = 1,
	//! Indicates exact specification in millimetres.
	SeaAspectTypeExactMillimeter = 2,
	
	kNoAspectType NS_SWIFT_UNAVAILABLE("Use .None instead") = SeaAspectTypeNone,
	kRatioAspectType NS_SWIFT_UNAVAILABLE("Use .Ratio instead") = SeaAspectTypeRatio,
	kExactPixelAspectType NS_SWIFT_UNAVAILABLE("Use .ExactPixel instead") = SeaAspectTypeExactPixel,
	kExactInchAspectType NS_SWIFT_UNAVAILABLE("Use .ExactInch instead") = SeaAspectTypeExactInch,
	kExactMillimeterAspectType NS_SWIFT_UNAVAILABLE("Use .ExactMillimeter instead") = SeaAspectTypeExactMillimeter,
};

@class SeaDocument;

/*		
	@class		AspectRatio
	@abstract	Collects common aspect ratio code.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2007 Mark Pazolli
*/
@interface AspectRatio : NSObject {
	// The host document
	IBOutlet SeaDocument *document;

	// The controlling object
	__weak id master;

	// The controlling object's identifier (used for preferences)
	NSString *prefString;

	// When checked indicates the cropping aspect ratio should be restricted
	IBOutlet NSButton *ratioCheckbox;
	
	// A popup menu indicating the aspect ratio
	IBOutlet NSPopUpButton *ratioPopup;
	
	// A panel for selecting the custom aspect ratio
	IBOutlet NSPanel *panel;
	
	// Text boxes for custom ratio values
    IBOutlet NSTextField *xRatioValue;
    IBOutlet NSTextField *yRatioValue;
	
	// Various items associated with the aspect type
	IBOutlet NSTextField *toLabel;
	IBOutlet NSPopUpButton *aspectTypePopup;
	
	// Custom ratio values
	CGFloat ratioX, ratioY;
	
	// Forgotten values
	CGFloat forgotX, forgotY;
	
	// The type of aspect ratio
	SeaAspectType aspectType;
	
}

- (void)awakeWithMaster:(id)imaster andString:(NSString*)iprefString;

/*!
	@method		setCustomItem:
	@discussion	Presents dialog for setting the custom item.
	@param		sender
				Ignored.
*/
- (IBAction)setCustomItem:(id)sender;

/*!
	@method		applyCustomItem:
	@discussion	Applies dialog changes to the custom item.
	@param		sender
				Ignored.
*/
- (IBAction)applyCustomItem:(id)sender;

/*!
	@method		changeCustomAspectType:
	@discussion	Changes the aspect type in the dialog.
	@param		sender
				Ignored.
*/
- (IBAction)changeCustomAspectType:(id)sender;

/*!
	@property	ratioX
	@discussion	Returns the ratio/size for the crop.
	@return		Returns a NSSize for the crop in the aspect type's
				units. If it is a ratio the width = X / Y and the 
				height = Y / X.
*/
@property (readonly) NSSize ratio;

/*!
	@property	aspectType
	@discussion	Returns the type of aspect ratio.
	@return		Returns a constant representing the type of aspect ratio
				(see AspectRatio).
*/
@property (readonly) SeaAspectType aspectType;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
