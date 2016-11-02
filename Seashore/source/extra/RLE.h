/*!
	@header		RLE
	@abstract	Contains functions to allow RLE compression and decomprssion.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif

__BEGIN_DECLS

/*!
	@function	SeaRLEDecompress
	@discussion	Decompresses a given tile compressed with RLE.
	@param		output
				The block of memory in which to place the decompressed data,
				should be at least width * height * spp bytes long.
	@param		input
				The block of memory containing the compressed tile.
	@param		inputLength
				The length of the input block of memory, this may or may not
				exceed the length of the compressed data but prevents buffer
				overflow.
	@param		width
				The width of the tile.
	@param		height
				The height of the tile.
	@param		spp
				The samples per pixel of the tile.
	@result		Returns a YES upon success, NO otherwise.
*/
BOOL SeaRLEDecompress(unsigned char *output, unsigned char *input, int inputLength, int width, int height, int spp);

/*!
	@function	SeaRLECompress
	@discussion	Compresses a given tile with RLE.
	@param		output
				The block of memory in which to place the compressed data,
				should be at least d + 1 + (d / 128) * 3  bytes long where d =
				width * height * spp.
	@param		input
				The block of memory containing the uncompressed tile.
	@param		width
				The width of the tile.
	@param		height
				The height of the tile.
	@param		spp
				The samples per pixel of the tile.
	@result		Returns a YES upon success, NO otherwise.
*/
int SeaRLECompress(unsigned char *output, unsigned char *input, int width, int height, int spp);

__END_DECLS
