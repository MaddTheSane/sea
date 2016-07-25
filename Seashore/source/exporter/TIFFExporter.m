#import "TIFFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import <TIFF/tiff.h>
#import <TIFF/tiffio.h>

CF_ENUM(int) {
   openReadSpool = 1,	/* start read data process */
   openWriteSpool= 2,	/* start write data process */
   readSpool   = 3,		/* read specified number of bytes */
   writeSpool  = 4,		/* write specified number of bytes */
   closeSpool  = 5		/* complete data transfer process */
}; 

@implementation TIFFExporter

- (BOOL)hasOptions
{
	return YES;
}

- (IBAction)showOptions:(id)sender
{
	// Work things out
	if ([[idocument contents] cmykSave])
		[targetRadios selectCellAtRow:1 column:0];
	else
		[targetRadios selectCellAtRow:0 column:0];
	
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
}

- (IBAction)targetChanged:(id)sender
{
	switch ([targetRadios selectedRow]) {
		case 0:
			[[idocument contents] setCMYKSave:NO];
		break;
		case 1:
			[[idocument contents] setCMYKSave:YES];
		break;
	}
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"TIFF image";
}

- (NSString *)fileType
{
	return (NSString*)kUTTypeTIFF;
}

- (NSString *)extension
{
	return @"tiff";
}

- (NSString *)optionsString
{
	if ([[idocument contents] cmykSave])
		return @"CMYK";
	else
		return @"RGB/RGBA";
}

- (BOOL)writeDocument:(SeaDocument*)document toFile:(NSString *)path
{
	int i, j, width, height, spp, xres, yres, linebytes;
	unsigned char *srcData, *tempData, *destData, *buf;
	//NSBitmapImageRep *imageRep;
	BOOL hasAlpha = NO;
	BOOL cmOkay = NO;
	
	ColorSyncProfileRef cmProfile;
	ColorSyncProfileRef srcProf, destProf;
	ColorSyncTransformRef cw;
	TIFF *tiff;

	// Get the data to write
	srcData = [[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Determine whether or not an alpha channel would be redundant
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Behave differently if we are targeting a CMYK file
	if ([[document contents] cmykSave] && spp == 4) {
	
		// Strip the alpha channel
		tempData = malloc(width * height * 3);
		SeaStripAlphaToWhite(spp, tempData, srcData, width * height);
		spp--;
		
		// Establish the color world
		srcProf = ColorSyncProfileCreateWithDisplayID(0);
		destProf = ColorSyncProfileCreateWithName(kColorSyncGenericCMYKProfile);
		NSArray<NSDictionary<NSString*,id>*>*
		profSeq = @[
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)srcProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformDeviceToPCS,
					  },
					
					@{(__bridge NSString*)kColorSyncProfile: (__bridge id)destProf,
					  (__bridge NSString*)kColorSyncRenderingIntent: (__bridge NSString*)kColorSyncRenderingIntentPerceptual,
					  (__bridge NSString*)kColorSyncTransformTag: (__bridge NSString*)kColorSyncTransformPCSToDevice,
					  },
					];
		
		cw = ColorSyncTransformCreate((__bridge CFArrayRef)(profSeq), NULL);
		
		destData = malloc(width * height * 4);

		ColorSyncTransformConvert(cw, width, height, destData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaNone, width * 4, tempData, kColorSync8BitInteger, kColorSyncByteOrderDefault | kColorSyncAlphaNone, width * 3, NULL);
		
		// Clean up after ourselves
		if (cw) CFRelease(cw);
		free(tempData);
		CFRelease(srcProf);
		
		// Embed ColorSync profile
		NSData *cmData = CFBridgingRelease(ColorSyncProfileCopyData(destProf, NULL));
		cmOkay = NO;
		if (cmData) {
			cmOkay = YES;
		}
		CFRelease(destProf);
		
		// Open the file for writing
		tiff = TIFFOpen([path fileSystemRepresentation], "w");
		
		// Write the data
		TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, (uint32)width);
		TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, (uint32)height);
		TIFFSetField(tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
		TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, 4);
		TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, 8);
		TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
		TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_SEPARATED);
		TIFFSetField(tiff, TIFFTAG_INKSET, INKSET_CMYK);
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW);
		TIFFSetField(tiff, TIFFTAG_PREDICTOR, PREDICTOR_HORIZONTAL);
		TIFFSetField(tiff, TIFFTAG_XRESOLUTION, (float)xres);
		TIFFSetField(tiff, TIFFTAG_YRESOLUTION, (float)yres);
		TIFFSetField(tiff, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);
		TIFFSetField(tiff, TIFFTAG_SOFTWARE, "Seashore 0.2.0");
		if (cmOkay) TIFFSetField(tiff, TIFFTAG_ICCPROFILE, (int)cmData.length, cmData.bytes);
		TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, (width * 4 * height > 8192) ? (8192 / (width * 4) + 1) : height);
		linebytes = 4 * width;
		if (TIFFScanlineSize(tiff) > linebytes) {
			buf = (unsigned char *)malloc(TIFFScanlineSize(tiff));
			memset(buf, 0, TIFFScanlineSize(tiff));
		}
		else {
			buf = (unsigned char *)malloc(linebytes);
		}
		for (i = 0; i < height; i++) {
			memcpy(buf, &(destData[width * 4 * i]), linebytes);
			if (TIFFWriteScanline(tiff, buf, i, 0) < 0) {
				if (destData != srcData) free(destData);
				return NO;
			}
		}
		
		// Close the file
		TIFFClose(tiff);
		free(buf);
	}
	else {
		
		// Strip the alpha channel if necessary
		if (!hasAlpha) {
			spp--;
			destData = malloc(width * height * spp);
			for (i = 0; i < width * height; i++) {
				for (j = 0; j < spp; j++)
					destData[i * spp + j] = srcData[i * (spp + 1) + j];
			}
		}
		else {
			destData = malloc(width * height * spp);
			SeaUnpremultiplyBitmap(spp, destData, srcData, width * height);
		}
		
		// Get embedded ColorSync profile
		if (spp < 3)
			cmProfile = ColorSyncProfileCreateWithName(kColorSyncGenericGrayProfile);
		else
			cmProfile = ColorSyncProfileCreateWithDisplayID(0);
		NSData *cmData = CFBridgingRelease(ColorSyncProfileCopyData(cmProfile, NULL));
		BOOL cmOkay = NO;
		if (cmData) {
			cmOkay = YES;
		}
		CFRelease(cmProfile);
		cmProfile = nil;
		
		// Open the file for writing
		tiff = TIFFOpen([path fileSystemRepresentation], "w");
		
		// Write the data
		TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, (uint32)width);
		TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, (uint32)height);
		TIFFSetField(tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
		TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, spp);
		TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, 8);
		TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
		if (spp < 3)
			TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
		else
			TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW);
		TIFFSetField(tiff, TIFFTAG_PREDICTOR, PREDICTOR_HORIZONTAL);
		TIFFSetField(tiff, TIFFTAG_XRESOLUTION, (float)xres);
		TIFFSetField(tiff, TIFFTAG_YRESOLUTION, (float)yres);
		TIFFSetField(tiff, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);
		TIFFSetField(tiff, TIFFTAG_SOFTWARE, "Seashore 0.1.9");
		if (cmOkay) TIFFSetField(tiff, TIFFTAG_ICCPROFILE, (int)cmData.length, cmData.bytes);
		TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, (width * spp * height > 8192) ? (8192 / (width * spp) + 1) : height);
		linebytes = spp * width;
		if (TIFFScanlineSize(tiff) > linebytes) {
			buf = (unsigned char *)malloc(TIFFScanlineSize(tiff));
			memset(buf, 0, TIFFScanlineSize(tiff));
		}
		else {
			buf = (unsigned char *)malloc(linebytes);
		}
		for (i = 0; i < height; i++) {
			memcpy(buf, &(destData[width * spp * i]), linebytes);
			if (TIFFWriteScanline(tiff, buf, i, 0) < 0) {
				if (destData != srcData) free(destData);
				return NO;
			}
		}
		
		// Close the file
		TIFFClose(tiff);
		free(buf);
	}
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end
