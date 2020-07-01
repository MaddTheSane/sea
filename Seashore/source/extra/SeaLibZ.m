//
//  SeaLibZ.m
//  SeashoreKit
//
//  Created by C.W. Betts on 6/30/20.
//

#import "SeaLibZ.h"
#include <zlib.h>

BOOL SeaZDecompress(unsigned char *output, unsigned char *input, int inputLength, int width, int height, int spp)
{
	z_stream  strm;
	int       action;
	int       status;

	
	strm.next_out  = output;
	strm.avail_out = make_128(width * height * spp);

	strm.zalloc    = Z_NULL;
	strm.zfree     = Z_NULL;
	strm.opaque    = Z_NULL;
	strm.next_in   = input;
	strm.avail_in  = inputLength;

	status = inflateInit(&strm);
	if (status != Z_OK) {
		return NO;
	}
	
	action = Z_NO_FLUSH;

	while (status == Z_OK) {
		if (strm.avail_in == 0) {
			action = Z_FINISH;
		}
		
		status = inflate(&strm, action);
		
		if (status == Z_STREAM_END) {
			/* All the data was successfully decoded. */
			break;
		} else if (status == Z_BUF_ERROR) {
			//g_printerr("xcf: decompressed tile bigger than the expected size.");
			inflateEnd(&strm);
			return NO;
		} else if (status != Z_OK) {
			//g_printerr("xcf: tile decompression failed: %s", zError (status));
			inflateEnd(&strm);
			return NO;
		}
	}

	
	inflateEnd(&strm);

	return NO;
}

int SeaZCompress(unsigned char *output, unsigned char *input, int width, int height, int spp)
{
	return 0;
}
