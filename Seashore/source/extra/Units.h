/*!
	@header		Units
	@abstract	Contains various fuctions relating to units.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
*/

#import <Foundation/Foundation.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
	@enum		k...Units
	@constant	kPixelUnits
				The units are pixels.
	@constant	kInchUnits
				The units are inches.
	@constant	kMillimeterUnits
				The units are millimetres.
*/
typedef NS_ENUM(NSInteger, SeaUnits) {
	kPixelUnits,
	kInchUnits,
	kMillimeterUnits
};

/*!
	@function	SeaStringFromPixels
	@discussion	Converts a number of pixels to a string represeting the given units.
	@param		pixels
				The number of pixels.
	@param		units
				The units being used.
	@param		resolution
				The resolution being used.
	@result		Returns an NSString that is good for displaying the units.
*/
NSString *SeaStringFromPixels(int pixels, SeaUnits units, int resolution);

/*!
	@function	SeaPixelsfromFloat
	@discussion	Converts a float represeting the given units into a number of pixels.
	@param		measure
				The measure being converted.
	@param		units
				The units being used.
	@param		resolution
				The resolution being used.
	@result		Returns an int that is the exact number of pixels.
*/
int SeaPixelsFromFloat(CGFloat measure, SeaUnits units, int resolution);

/*!
	@function	SeaUnitsString
	@discussion	Gives a label to different unit types.
	@param		units
				The units to display.
	@result		Returns an NSString that is the label for the units.
*/
NSString *SeaUnitsString(SeaUnits units);

NS_ASSUME_NONNULL_END
