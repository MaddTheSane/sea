#include <stdlib.h>
#import "Bitmap.h"
#import "bitstring.h"

#define kMaxPtrsInPtrRecord 8

typedef struct {
	unsigned char *ptrs[kMaxPtrsInPtrRecord];
	int n;
	size_t init_size;
} PtrRecord;

static inline PtrRecord initPtrs(unsigned char *initial, size_t init_size)
{
	PtrRecord ptrs;
	
	ptrs.ptrs[0] = initial;
	ptrs.n = 1;
	ptrs.init_size = init_size;
	
	return ptrs;
}

static inline unsigned char *getPtr(PtrRecord ptrs)
{
	return ptrs.ptrs[ptrs.n - 1];
}

static inline unsigned char *getFinalPtr(PtrRecord ptrs)
{
	unsigned char *result;
	
	if (ptrs.n == 0) {
		result = malloc(make_128(ptrs.init_size));
		memcpy(result, ptrs.ptrs[0], ptrs.init_size);
	}
	else {
		result = ptrs.ptrs[ptrs.n - 1];
	}
	
	return result;
}

static inline unsigned char *mallocPtr(PtrRecord *ptrs, size_t size)
{
	unsigned char *result;
	
	if (ptrs->n < kMaxPtrsInPtrRecord) {
		ptrs->ptrs[ptrs->n] = malloc(make_128(size));
		result = ptrs->ptrs[ptrs->n];
		ptrs->n++;
	}
	else {
		NSLog(@"Cannot add more pointers to pointer record");
		result = NULL;
	}
	
	return result;
}

static inline void freePtrs(PtrRecord ptrs)
{
	size_t i;
	
	for (i = 1; i < ptrs.n - 1; i++) {
		free(ptrs.ptrs[i]);
	}
}

static inline void rotate_bytes(unsigned char *data, size_t pos1, size_t pos2)
{
	unsigned char tmp;
	ssize_t i;
	
	tmp = data[pos1];
	for (i = pos1; i < pos2 - 1; i++) data[i] = data[i + 1];
	data[pos2] = tmp;
}

static void covertBitmapColorSyncProfile(unsigned char *dbitmap, NSInteger dspp, BMPColorSpace dspace, unsigned char *ibitmap, NSInteger width, NSInteger height, NSInteger ispp, BMPColorSpace ispace, NSInteger ibps, ColorSyncProfileRef iprofile)
{
	ColorSyncDataDepth srcDepth = 0;
	ColorSyncDataDepth dstDepth = kColorSync8BitInteger;
	ColorSyncDataLayout dstLayout = kColorSyncAlphaLast | kColorSyncByteOrderDefault;
	ColorSyncDataLayout srcLayout = 0;
	ColorSyncProfileRef destProf = NULL;
	size_t srcBytesPerRow = 0;
	size_t dstBytesPerRow = 0;
	ColorSyncTransformRef cw = NULL;
	
	switch (ispace) {
		case BMPColorSpaceGray:
		case BMPColorSpaceInvertedGray:
			if (ibps == 8) {
				srcDepth = kColorSync8BitInteger;
			} else {
				srcDepth = kColorSync16BitInteger;
			}
			if (ispp == 1) {
				srcLayout = kColorSyncByteOrderDefault | kColorSyncAlphaNone;
			} else {
				srcLayout = kColorSyncByteOrderDefault | kColorSyncAlphaLast;
			}
			srcBytesPerRow = width * ispp * (ibps / 8);
			break;
			
		case BMPColorSpaceRGB:
			if (ibps == 8) {
				srcDepth = kColorSync8BitInteger;
			} else {
				srcDepth = kColorSync16BitInteger;
			}
			if (ispp == 3) {
				srcLayout = kColorSyncByteOrderDefault | kColorSyncAlphaNone;
			} else {
				srcLayout = kColorSyncByteOrderDefault | kColorSyncAlphaLast;
			}
			srcBytesPerRow = width * ispp * (ibps / 8);
			break;
			
		case BMPColorSpaceCMYK:
			if (ibps == 8) {
				srcDepth = kColorSync8BitInteger;
			} else {
				srcDepth = kColorSync16BitInteger;
			}
			srcLayout = kColorSyncByteOrderDefault | kColorSyncAlphaNone;
			srcBytesPerRow = width * ispp * (ibps / 8);
			break;

		default:
			break;
	}
	
	switch (dspace) {
		case BMPColorSpaceGray:
		case BMPColorSpaceInvertedGray:
			destProf = ColorSyncProfileCreateWithName(kColorSyncGenericGrayProfile);
			dstBytesPerRow = width * 2;
			break;
			
		case BMPColorSpaceRGB:
			destProf = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
			dstBytesPerRow = width * 4;
			break;
			
		default:
			break;
	}
	
	// Execute the conversion
	NSArray<NSDictionary<NSString*,id>*>*
	profSeq = @[
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)iprofile,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
				  },
				
				@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
				  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
				  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
				  },
				];
	
	cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
	ColorSyncTransformConvert(cw, width, height, dbitmap, dstDepth, dstLayout, dstBytesPerRow, ibitmap, srcDepth, srcLayout, srcBytesPerRow, NULL);
	CFRelease(destProf);
	CFRelease(cw);
}

/*
	Gray -> Gray
	RGB -> RGB
	Gray -> RGB
	RGB -> Gray
*/

static void covertBitmapNoColorSync(unsigned char *dbitmap, NSInteger dspp, BMPColorSpace dspace, unsigned char *ibitmap, NSInteger width, NSInteger height, NSInteger ispp, BMPColorSpace ispace, NSInteger ibps)
{
	if (ispace == BMPColorSpaceGray && dspace == BMPColorSpaceGray) {
		if (ibps == 8) {
			if (ispp == 2) {
				memcpy(dbitmap, ibitmap, width * height * 2);
			} else {
				for (int i = 0; i < width * height; i++) {
					dbitmap[i * 2] = ibitmap[i * 1];
				}
			}
		} else if (ibps == 16) {
			for (int i = 0; i < width * height; i++) {
				for (int j = 0; j < ispp; j++) {
					dbitmap[i * 2 + j] = ibitmap[i * ispp * 2 + j * 2 + MSB];
				}
			}
		}
	} else if (ispace == BMPColorSpaceRGB && dspace == BMPColorSpaceRGB) {
		if (ibps == 8) {
			if (ispp == 4) {
				memcpy(dbitmap, ibitmap, width * height * 4);
			} else {
				for (int i = 0; i < width * height; i++) {
					memcpy(&(dbitmap[i * 4]), &(ibitmap[i * 3]), 3);
				}
			}
		} else if (ibps == 16) {
			for (int i = 0; i < width * height; i++) {
				for (int j = 0; j < ispp; j++) {
					dbitmap[i * 4 + j] = ibitmap[i * ispp * 2 + j * 2 + MSB];
				}
			}
		}
	} else if (ispace == BMPColorSpaceGray && dspace == BMPColorSpaceRGB) {
		if (ibps == 8) {
			for (int i = 0; i < width * height; i++) {
				dbitmap[i * 4] = dbitmap[i * 4 + 1] = dbitmap[i * 4 + 2] = ibitmap[i * ispp];
				if (ispp == 2) dbitmap[i * 4 + 3] = ibitmap[i * ispp + 1];
			}
		} else if (ibps == 16) {
			for (int i = 0; i < width * height; i++) {
				dbitmap[i * 4] = dbitmap[i * 4 + 1] = dbitmap[i * 4 + 2] = ibitmap[i * ispp * 2 + MSB];
				if (ispp == 2) dbitmap[i * 4 + 3] = ibitmap[i * 4 + 2 + MSB];
			}
		}
	} else if (ispace == BMPColorSpaceRGB && dspace == BMPColorSpaceGray) {
		if (ibps == 8) {
			for (int i = 0; i < width * height; i++) {
				dbitmap[i * 2] = ((int)ibitmap[i * ispp] + (int)ibitmap[i * ispp + 1] + (int)ibitmap[i * ispp + 2]) / 3;
				if (ispp == 4) dbitmap[i * 2 + 1] = ibitmap[i * 4 + 3];
			}
		} else if (ibps == 16) {
			for (int i = 0; i < width * height; i++) {
				dbitmap[i * 2] = ((int)ibitmap[i * ispp * 2 + MSB] + (int)ibitmap[i * ispp * 2 + 2 + MSB] + (int)ibitmap[i * ispp * 2 + 4 + MSB]) / 3;
				if (ispp == 4) dbitmap[i * 2 + 1] = ibitmap[i * 8 + 6 + MSB];
			}
		}
	}
}

unsigned char *SeaConvertBitmap(NSInteger dspp, BMPColorSpace dspace, NSInteger dbps, unsigned char *ibitmap, NSInteger width, NSInteger height, NSInteger ispp, NSInteger ibipp, NSInteger ibypr, BMPColorSpace ispace, ColorSyncProfileRef iprofile, NSInteger ibps, GIMPBitmapFormat iformat)
{
	PtrRecord ptrs;
	unsigned char *bitmap, *pbitmap;
	NSInteger pos;
	BOOL s_hasalpha;
	NSString *fail;
	
#ifdef DEBUG
	if (!iprofile) {
		NSLog(@"No ColorSync profile!");
	}
#endif
	
	// Point out conversions that are not possible
	fail = NULL;
	if (dbps != 8) fail = @"Only converts to 8 bps";
	if (dspace == BMPColorSpaceCMYK) fail = @"Cannot convert to CMYK color space";
	if (dspace == BMPColorSpaceInvertedGray) fail = @"Cannot convert to inverted gray color space";
	if (dspace == BMPColorSpaceRGB && dspp != 4) fail = @"Can only convert to 4 spp for RGB color space";
	if (dspace == BMPColorSpaceGray && dspp != 2) fail = @"Can only convert to 2 spp for RGB color space";
	if (fail) { NSLog(@"%@", fail); return NULL; }
	
	// Create initial pointer
	ptrs = initPtrs(ibitmap, ibypr * height);
	
	// Convert to from 1-, 2- or 4-bit to 8-bit
	if (ibps < 8) {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * ispp);
		for (int j = 0; j < height; j++) {
			for (int i = 0; i < width; i++) {
				for (int k = 0; k < ispp; k++) {
					pos = (j * width + i) * ispp + k;
					bitmap[pos] = 0;
					for (int l = 0; l < ibps; l++) {
						if (bit_test(&pbitmap[j * ibypr + (i * ibipp + l) / 8], 7 - ((i * ibipp + l) % 8))) {
							bit_set(&bitmap[pos], l);
						}
						bitmap[pos] *= (255 / ((1 << ibps) - 1));
					}
				}
			}
		}
		ibps = 8;
		ibipp = ispp * 8;
		ibypr = width * ispp;
		iprofile = NULL; /* Sorry no ColorSync profiles for less than 8 bits */
	}
	
	// Remove redundant bits and bytes
	if (ibps == 8) {
		if (ibipp != ispp * 8 || ibypr != width * ispp) {
			pbitmap = getPtr(ptrs);
			bitmap = mallocPtr(&ptrs, width * height * ispp);
			for (int j = 0; j < height; j++) {
				for (int i = 0; i < width; i++) {
					for (int k = 0; k < ispp; k++) {
						bitmap[(j * width + i) * ispp + k] = pbitmap[j * ibypr + i * (ibipp / 8) + k];
					}
				}
			}
			ibipp = ispp * 8;
			ibypr = width * ispp;
		}
	} else if (ibps == 16) {
		if (ibipp != ispp * 16 || ibypr != width * ispp * 2) {
			pbitmap = getPtr(ptrs);
			bitmap = mallocPtr(&ptrs, width * height * ispp * 2);
			for (int j = 0; j < height; j++) {
				for (int i = 0; i < width; i++) {
					for (int k = 0; k < ispp; k++) {
						bitmap[((j * width + i) * ispp + k) * 2] = pbitmap[j * ibypr + i * (ibipp / 8) + k * 2];
						bitmap[((j * width + i) * ispp + k) * 2 + 1] = pbitmap[j * ibypr + i * (ibipp / 8) + k * 2 + 1];
					}
				}
			}
			ibipp = ispp * 16;
			ibypr = width * ispp * 2;
		}
	}
	
	// Swap alpha (if necessary)
	if (iformat & GIMPBitmapFormatAlphaFirst) {
		pbitmap = getPtr(ptrs); /* Note: transform is destructive (other destructive transforms follow) */
		if (ibps == 8) {
			for (int i = 0; i < width * height; i++) {
				rotate_bytes(pbitmap, i * ispp, (i + 1) * ispp - 1);
			}
		} else if (ibps == 16) {
			pbitmap = getPtr(ptrs);
			for (int i = 0; i < width * height; i++) {
				rotate_bytes(pbitmap, i * ispp * 2, i * ispp * 2 - 1);
				rotate_bytes(pbitmap, i * ispp * 2, i * ispp * 2 - 1);
			}
		}
		iformat &= ~(GIMPBitmapFormatAlphaFirst);
	}
	
	// Convert inverted gray color space
	if (ispace == BMPColorSpaceInvertedGray) {
		pbitmap = getPtr(ptrs);
		if (ibps == 8) {
			for (int i = 0; i < width * height; i++) {
				pbitmap[i * ispp] = ~pbitmap[i * ispp];
			}
		} else if (ibps == 16) {
			for (int i = 0; i < width * height; i++) {
				pbitmap[i * ispp * 2] = ~pbitmap[i * ispp * 2];
				pbitmap[i * ispp * 2 + 1] = ~pbitmap[i * ispp * 2 + 1];
			}
		}
		ispace = BMPColorSpaceGray;
	}
	
	// Convert colour space
	if (iprofile || ispace == BMPColorSpaceCMYK) {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * dspp);
		covertBitmapColorSyncProfile(bitmap, dspp, dspace, pbitmap, width, height, ispp, ispace, ibps, iprofile);
	} else {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * dspp);
		covertBitmapNoColorSync(bitmap, dspp, dspace, pbitmap, width, height, ispp, ispace, ibps);
	}
	
	// Add in alpha (not 16-bit friendly)
	s_hasalpha = (ispace == BMPColorSpaceRGB && ispp == 4) || (ispace == BMPColorSpaceGray && ispp == 2);
	if (!s_hasalpha) {
		for (int i = 0; i < width * height; i++) {
			pbitmap = getPtr(ptrs);
			pbitmap[(i + 1) * dspp - 1] = 255;
		}
	}
	
	// Return result
	freePtrs(ptrs);
	
	return getFinalPtr(ptrs);
}

void SeaStripAlphaToWhite(NSInteger spp, unsigned char *output, unsigned char *input, NSInteger length)
{
	const NSInteger alphaPos = spp - 1;
	const NSInteger outputSPP = spp - 1;
	unsigned char alpha;
	double alphaRatio;
	NSInteger t1, t2, newValue;
	
	memset(output, 255, length * outputSPP);
	
	for (NSInteger i = 0; i < length; i++) {
		
		alpha = input[i * spp + alphaPos];
		
		if (alpha == 255) {
			for (NSInteger k = 0; k < outputSPP; k++)
				output[i * outputSPP + k] = input[i * spp + k];
		} else {
			if (alpha != 0) {

				alphaRatio = 255.0 / alpha;
				for (NSInteger k = 0; k < outputSPP; k++) {
					newValue = 0.5 + input[i * spp + k] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * outputSPP + k] = int_mult(newValue, alpha, t1) + int_mult(255, (255 - alpha), t2);
				}
				
			}
		}
	
	} 
}

void SeaPremultiplyBitmap(NSInteger spp, unsigned char *output, unsigned char *input, NSInteger length)
{
	NSInteger alphaPos, temp;
	
	for (NSInteger i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (NSInteger j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		}
		else {
			if (input[alphaPos] != 0) {
				for (NSInteger j = 0; j < spp - 1; j++)
					output[i * spp + j] = int_mult(input[i * spp + j], input[alphaPos], temp);
				output[alphaPos] = input[alphaPos];
			}
			else {
				for (NSInteger j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}

void SeaUnpremultiplyBitmap(NSInteger spp, unsigned char *output, unsigned char *input, NSInteger length)
{
	NSInteger i, j, alphaPos, newValue;
	double alphaRatio;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		} else {
			if (input[alphaPos] != 0) {
				alphaRatio = 255.0 / input[alphaPos];
				for (j = 0; j < spp - 1; j++) {
					newValue = 0.5 + input[i * spp + j] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * spp + j] = newValue;
				}
				output[alphaPos] = input[alphaPos];
			} else {
				for (j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}

unsigned char SeaAveragedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where)
{
	int total, count;
	int i, j;
	
	if (radius == 0) {
		return data[(where.y * width + where.x) * spp + component];
	}

	total = 0;
	count = 0;
	for (j = where.y - radius; j <= where.y + radius; j++) {
		for (i = where.x - radius; i <= where.x + radius; i++) {
			if (i >= 0 && i < width && j >= 0 && j < height) {
				total += data[(j * width + i) * spp + component];
				count++;
			}
		}
	}
	if (count == 0) {
		return total;
	}
	
	return (total / count);
}
