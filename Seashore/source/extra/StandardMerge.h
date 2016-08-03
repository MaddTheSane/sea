/*!
	@header		StandardMerge
	@abstract	Contains functions to help with the merging of layers, these
				functions are not AltiVec-enabled.
	@discussion	All functions in this header will return immediately if the
				source pixel is transparent or the opacity is zero.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

/*!
	@defined	RANDOM_SEED
	@discussion	The value to be used by the dissolve merge technique.
*/
#define RANDOM_SEED      314159265

/*!
	@defined	RANDOM_TABLE_SIZE
	@discussion	The size of the table to be used with the dissolve merge
				technique.
*/
#define RANDOM_TABLE_SIZE  4096

/*!
	@function	SeaReplaceMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
extern void SeaReplaceMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaReplacePrimaryMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel but only for the primary channels.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
extern void SeaReplacePrimaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaReplaceAlphaMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel but only for the alpha channel.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
extern void SeaReplaceAlphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaSpecialMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the special merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
extern void SeaSpecialMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaNormalMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the normal merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
extern void SeaNormalMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaEraseMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the erase merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
extern void SeaEraseMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaPrimaryMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the primary merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
	@param		lazy
				YES if merges to destination pixel whose alpha is zero should be
				skipped, NO otherwise.
*/
extern void SeaPrimaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity, BOOL lazy);

/*!
	@function	SeaAlphaMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the alpha merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
extern void SeaAlphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	SeaBlendPixel
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using a simple blending technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		blend
				The amount of blending to go on (between 0 and 255 inclusive).
*/
extern void SeaBlendPixel(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int blend);

/*!
	@function	SeaSelectMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the selected merge technique.
				Note for \c XCF_DISSOLVE_MODE you must call <code>srandom(randomTable[y %
				4096]); for (k = 0; k < x; k++)  random();</code> for the merge to
				work correctly.
	@param		choice
				The selected merge technique (see Constants documentation).
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
*/
extern void SeaSelectMerge(XcfLayerMode choice, int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc);

