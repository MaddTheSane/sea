#import <Cocoa/Cocoa.h>
#import <SeashoreKit/Globals.h>
#import <SeashoreKit/SeaAlignment.h>

@class SeaAlignment, SeaMargins, SeaResolution, SeaScale, SeaDocRotation;
@class SeaRotation, SeaFlip;

/*!
	@class		SeaOperations
	@abstract	Acts as a gateway to the various operations of Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/
@interface SeaOperations : NSObject

/*!
	@property	seaAlignment
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaAlignment class.
*/
@property (weak) IBOutlet SeaAlignment *seaAlignment;

/*!
	@property	seaMargins
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaMargins class.
*/
@property (weak) IBOutlet SeaMargins *seaMargins;

/*!
	@property	seaResoulution
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaResoulution class.
*/
@property (weak) IBOutlet SeaResolution *seaResolution;

/*!
	@property	seaScale
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaScale class.
*/
@property (weak) IBOutlet SeaScale *seaScale;

/*!
	@property	seaDocRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaDocRotation class.
*/
@property (weak) IBOutlet SeaDocRotation *seaDocRotation;

/*!
	@property	seaRotation
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaRotation class.
*/
@property (weak) IBOutlet SeaRotation *seaRotation;

/*!
	@property	seaFlip
	@discussion	Returns the instance of the same name.
	@result		Returns an instance of the SeaFlip class.
*/
@property (weak) IBOutlet SeaFlip *seaFlip;

@end
