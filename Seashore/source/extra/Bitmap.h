/*!
	@header		Bitmap
	@abstract	Contains various fuctions relating to bitmap manipulation.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

NS_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS

/*!
	@enum		k...ColorSpace
	@constant	BMPColorSpaceGray
				Indicates the gray/white colour space.
	@constant	BMPColorSpaceInvertedGray
				Indicates the gray/black colour space.
	@constant	BMPColorSpaceRGB
				Indicates the RGB colour space.
	@constant	BMPColorSpaceCMYK
				Indicates the CMYK colour space
*/
typedef NS_ENUM(int, BMPColorSpace) {
	//! Indicates the gray/white colour space.
	BMPColorSpaceGray,
	//! Indicates the gray/black colour space.
	BMPColorSpaceInvertedGray,
	//! Indicates the RGB colour space.
	BMPColorSpaceRGB,
	//! Indicates the CMYK colour space.
	BMPColorSpaceCMYK,
	BMPColorSpaceInvalid = -1,
};

/*!
	@function	convertBitmap
	@discussion	Given a bitmap converts the bitmap to the given type. The
				conversion will not affect the premultiplication of the data.
	@param		dspp
				The samples per pixel of the desired bitmap.
	@param		dspace
				The colour space of the desired bitmap.
	@param		dbps
				The bits per sample of the desired bitmap.
	@param		ibitmap
				The original bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		ispp
				The samples per pixel of the original bitmap.
	@param		iebpp
				The number of extra bytes per pixel of the original bitmap.
	@param		iebpr
				The number of extra bytes per row of the original bitmap.
	@param		ispace
				The colour space of the original bitmap.
	@param		iprofile
				The location of the ColorSync profile of the original bitmap or
				NULL if none exists.
	@param		ibps
				The bits per sample of the original bitmap.
	@param		iformat
				The format of the original bitmap.
	@result		Returns a block of memory containing the desired bitmap which
				must be freed after use or NULL if the conversion was not
				possible. You should always check for failed conversions. The
				block of memory is safe for use with AltiVec.
*/
extern unsigned char *convertBitmap(int dspp, BMPColorSpace dspace, int dbps, unsigned char *ibitmap, int width, int height, BMPColorSpace ispp, int iebpp, int iebpr, int ispace, CMProfileLocation *iprofile, int ibps, NSBitmapFormat iformat) DEPRECATED_ATTRIBUTE UNAVAILABLE_ATTRIBUTE;

/*!
	@function	SeaConvertBitmap
	@discussion	Given a bitmap converts the bitmap to the given type. The
				conversion will not affect the premultiplication of the data.
	@param		dspp
				The samples per pixel of the desired bitmap.
	@param		dspace
				The colour space of the desired bitmap.
	@param		dbps
				The bits per sample of the desired bitmap.
	@param		ibitmap
				The original bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		ispp
				The samples per pixel of the original bitmap.
	@param		iebpp
				The number of extra bytes per pixel of the original bitmap.
	@param		iebpr
				The number of extra bytes per row of the original bitmap.
	@param		ispace
				The colour space of the original bitmap.
	@param		iprofile
				The ColorSync profile of the original bitmap or
				\c NULL if none exists.
	@param		ibps
				The bits per sample of the original bitmap.
	@param		iformat
				The format of the original bitmap.
	@result		Returns a block of memory containing the desired bitmap which
				must be freed after use or \c NULL if the conversion was not
				possible. You should \a always check for failed conversions. The
				block of memory is safe for use with AltiVec.
 */
extern unsigned char *__nullable SeaConvertBitmap(NSInteger dspp, BMPColorSpace dspace, NSInteger dbps, unsigned char *ibitmap, NSInteger width, NSInteger height, NSInteger ispp, NSInteger iebpp, NSInteger iebpr, BMPColorSpace ispace, ColorSyncProfileRef __nullable iprofile, NSInteger ibps, GIMPBitmapFormat iformat) NS_SWIFT_NAME(convertBitmap(destinationSamplesPerPixel:destinationColorSpace:destinationBitsPerSample:bitmap:width:height:originalSamplesPerPixel:originalExtraBytesPerPixel:originalExtraBytesPerRow:originalColorSpace:profile:originalBitsPerSample:originalFormat:));


/*!
	@function	SeaStripAlphaToWhite
	@discussion	Given a bitmap this function strips the alpha channel making it
				appear as though the image is on a white background and places
				the result in the output. The output and input can both point to
				the same block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		output
				The block of memory in which to place the bitmap once its alpha
				channel has been stripped.
	@param		input
				The block of memory containing the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
extern void SeaStripAlphaToWhite(NSInteger spp, unsigned char *output, unsigned char *input, NSInteger length) NS_SWIFT_NAME(stripAlphaToWhite(originalSamplesPerPixel:output:input:length:));

/*!
	@function	SeaPremultiplyBitmap
	@discussion	Given a bitmap this function premultiplies the primary channels
				and places the result in the output. The output and input can 
				both point to the same block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		destPtr
				The block of memory in which to place the premultiplied bitmap.
	@param		srcPtr
				The block of memory containing the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
extern void SeaPremultiplyBitmap(NSInteger spp, unsigned char *destPtr, unsigned char *srcPtr, NSInteger length) NS_SWIFT_NAME(premultiplyBitmap(samplesPerPixel:destination:source:length:));

/*!
	@function	SeaUnpremultiplyBitmap
	@discussion	Given a bitmap this function tries to reverse the
				premultiplication of the primary channels and places the result
				in the output. The output and input can  both point to the same
				block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		destPtr
				The block of memory in which to place the premultiplied bitmap.
	@param		srcPtr
				The block of memory containing the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
extern void SeaUnpremultiplyBitmap(NSInteger spp, unsigned char *destPtr, unsigned char *srcPtr, NSInteger length) NS_SWIFT_NAME(unpremultiplyBitmap(samplesPerPixel:destination:source:length:));

/*!
	@function	SeaAveragedComponentValue
	@discussion	Given a point on the bitmap this function finds the average
				value of particular component inside a box about that point.
	@param		spp
				The samples per pixel of the bitmap.
	@param		data
				The block of memory containing the bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		component
				The component on which to focus (must be less than the spp of
				the bitmap).
	@param		radius
				The radius of the box on which to focus (a radius of zero simply
				returns the component value at the given point).
	@param		where
				The point at which to centre the box.
*/
extern unsigned char SeaAveragedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where) NS_SWIFT_NAME(averagedComponentValue(samplesPerPixel:data:width:height:component:radius:centerPoint:));


/*!
	@function	OpenDisplayProfile
	@discussion	Returns the ColorSync profile for the default display.
	@param		profile
				The profile to make the default display's profile.
*/
extern void OpenDisplayProfile(CMProfileRef __nonnull*__nullable profile) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER UNAVAILABLE_ATTRIBUTE;

/*!
	@function	CloseDisplayProfile
	@discussion	Releases the ColorSync profile for the default display.
	@param		profile
				The profile to make the default display's profile.
*/
extern void CloseDisplayProfile(CMProfileRef profile) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER UNAVAILABLE_ATTRIBUTE;

void CMFlattenProfile(CMProfileRef _Null_unspecified pref, int flags, CMFlattenUPP  _Null_unspecified* _Null_unspecified cmFlattenUPP, void * _Null_unspecified refcon, Boolean *_Null_unspecified cmmNotFound) DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER UNAVAILABLE_ATTRIBUTE;

static const BMPColorSpace kGrayColorSpace NS_DEPRECATED_WITH_REPLACEMENT_MAC("BMPColorSpaceGray", 10.2, 10.8) = BMPColorSpaceGray;
static const BMPColorSpace kInvertedGrayColorSpace NS_DEPRECATED_WITH_REPLACEMENT_MAC("BMPColorSpaceInvertedGray", 10.2, 10.8) = BMPColorSpaceInvertedGray;
static const BMPColorSpace kRGBColorSpace NS_DEPRECATED_WITH_REPLACEMENT_MAC("BMPColorSpaceRGB", 10.2, 10.8) = BMPColorSpaceRGB;
static const BMPColorSpace kCMYKColorSpace NS_DEPRECATED_WITH_REPLACEMENT_MAC("BMPColorSpaceCMYK", 10.2, 10.8) = BMPColorSpaceCMYK;

__END_DECLS
NS_ASSUME_NONNULL_END
