#import "JP2Exporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaDocument.h"
#import "Bitmap.h"

static unsigned char *cmData;
static unsigned int cmLen;

@implementation JP2Exporter

- (id)init
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"jp2 target"] == NULL)
		targetWeb = YES;
	else
		targetWeb = [defaults boolForKey:@"jp2 target"];
	
	if ([defaults objectForKey:@"jp2 web compression"] == NULL) {
		value = 26;
	}
	else {
		value = [defaults integerForKey:@"jp2 web compression"];
		if (value < 0 || value > kMaxCompression)
			value = 26;
	}
	webCompression = value;
	
	if ([defaults objectForKey:@"jp2 print compression"] == NULL) {
		value = 30;
	}
	else {
		value = [defaults integerForKey:@"jp2 print compression"];
		if (value < 0 || value > kMaxCompression)
			value = 30;
	}
	printCompression = value;
	
	return self;
}

- (BOOL)hasOptions
{
	return YES;
}

- (float)reviseCompression
{
	float result;
	
	if (targetWeb) {
		if (webCompression < 5) {
			result = 0.1 + 0.08 * (float)webCompression;
		}
		else if (webCompression < 10) {
			result = 0.3 + 0.04 * (float)webCompression;
		}
		else if (webCompression < 20) {
			result = 0.5 + 0.02 * (float)webCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)webCompression;
		}
	}
	else {
		if (printCompression < 5) {
			result = 0.1 + 0.08 * (float)printCompression;
		}
		else if (printCompression < 10) {
			result = 0.3 + 0.04 * (float)printCompression;
		}
		else if (printCompression < 20) {
			result = 0.5 + 0.02 * (float)printCompression;
		}
		else {
			result = 0.7 + 0.01 * (float)printCompression;
		}
	}
	[compressLabel setStringValue:[NSString stringWithFormat:@"Compressed - %d%%", (int)roundf(result * 100.0)]];
	
	return result;
}

/*
	if (spp == 4) {
		for (k = 0; k < 3; k++)
			sampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 4 + k];
		sampleData[(j * 40 + i) * 4] = data[(y * width + x) * 4 + 3];
	}
	else {
		for (k = 0; k < 3; k++)
			sampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 2];
		sampleData[(j * 40 + i) * 4] = data[(y * width + x) * 2 + 1];
	}
*/

- (void)showOptions:(id)document
{
	unsigned char *data;
	int width = [(SeaContent *)[document contents] width], height = [(SeaContent *)[document contents] height], spp = [[document contents] spp];
	int i, j, k, x, y;
	id realImage, compressImage;
	float value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Work things out
	if (targetWeb)
		[targetRadios selectCellAtRow:0 column:0];
	else
		[targetRadios selectCellAtRow:0 column:1];
	
	// Revise the compression
	if (targetWeb)
		[compressSlider setIntValue:webCompression];
	else
		[compressSlider setIntValue:printCompression];
	value = [self reviseCompression];
	
	// Set-up the sample data
	data = [(SeaWhiteboard *)[document whiteboard] data];
	sampleData = malloc(40 * 40 * 4);
	memset(sampleData, 0x00, 40 * 40 * 4);
	for (j = 0; j < 40; j++) {
		for (i = 0; i < 40; i++) {
			x = width / 2 - 20 + i;
			y = height / 2 - 20 + j;
			if (x >= 0 && x < width && y >= 0 && y < height) {
				if (spp == 4) {
					for (k = 0; k < 4; k++)
						sampleData[(j * 40 + i) * 4 + k] = data[(y * width + x) * 4 + k];
				}
				else {
					for (k = 0; k < 3; k++)
						sampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 2];
					sampleData[(j * 40 + i) * 4] = data[(y * width + x) * 2 + 1];
				}
			}
		}
	}
	premultiplyBitmap(4, sampleData, sampleData, 40 * 40);
	
	// Now make an image for the view
	realImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&sampleData pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:40 * 4 bitsPerPixel:8 * 4];
	realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
	[realImage addRepresentation:realImageRep];
	[realImageView setImage:realImage];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:@{NSImageCompressionFactor: @([self reviseCompression])}]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImageView setImage:compressImage];
	
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
	
	// Clean-up
	[defaults setObject:(targetWeb ? @"YES" : @"NO") forKey:@"jp2 target"];
	if (targetWeb)
		[defaults setInteger:webCompression forKey:@"jp2 web compression"];
	else
		[defaults setInteger:printCompression forKey:@"jp2 print compression"];
	free(sampleData);
}

- (IBAction)compressionChanged:(id)sender
{
	id compressImage;
	float value;
	
	if (targetWeb)
		webCompression = [compressSlider intValue];
	else
		printCompression = [compressSlider intValue];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:@{NSImageCompressionFactor: @([self reviseCompression])}]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImageView setImage:compressImage];
	[compressImageView display];
}

- (IBAction)targetChanged:(id)sender
{
	id compressImage;
	float value;
	
	// Determine the target
	if ([targetRadios selectedColumn] == 0)
		targetWeb = YES;
	else
		targetWeb = NO;
	
	// Revise the compression
	if (targetWeb)
		[compressSlider setIntValue:webCompression];
	else
		[compressSlider setIntValue:printCompression];
	value = [self reviseCompression];
	compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:@{NSImageCompressionFactor: @([self reviseCompression])}]];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImageView setImage:compressImage];
	[compressImageView display];
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"JPEG 2000 image";
}

- (NSString *)extension
{
	return @"jp2";
}

- (NSString *)optionsString
{
	if (targetWeb)
		return [NSString stringWithFormat:@"Web %.0f%%", [self reviseCompression] * 100.0];
	else
		return [NSString stringWithFormat:@"Print %.0f%%", [self reviseCompression] * 100.0];
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int width, height, spp;
	unsigned char *srcData, *destData;
	NSBitmapImageRep *imageRep;
	NSData *imageData;
	CMProfileRef cmProfile;
	BOOL hasAlpha = NO;
	int i, j;
	
	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	
	// Determine whether or not an alpha channel would be redundant
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Strip the alpha channel if necessary
	if (!hasAlpha) {
		spp--;
		destData = malloc(width * height * spp);
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp; j++)
				destData[i * spp + j] = srcData[i * (spp + 1) + j];
		}
	}
	else
		destData = srcData;

	// Make an image representation from the data
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	
	// Embed ColorSync profile
	if (!targetWeb) {
		if (spp < 3)
			CMGetDefaultProfileBySpace(cmGrayData, &cmProfile);
		else
			OpenDisplayProfile(&cmProfile);
		cmData = NULL;
		CMProfileLocation profileLoc;
		profileLoc.locType = cmBufferBasedProfile;
		profileLoc.u.bufferLoc.buffer = cmData;
		profileLoc.u.bufferLoc.size = cmLen;
		CMProfileRef tempProfile;
		CMCopyProfile(&tempProfile, &profileLoc, cmProfile);

		//CMFlattenProfile(cmProfile, 0, (CMFlattenUPP)&getcm, NULL, &cmmNotFound);
		if (cmData) {
			[imageRep setProperty:NSImageColorSyncProfileData withValue:[NSData dataWithBytes:cmData length:cmLen]];
			free(cmData);
		}
		if (spp >= 3) CloseDisplayProfile(cmProfile);
	}
	
	// Finally build the JPEG 2000 data
	imageData = [imageRep representationUsingType:NSJPEG2000FileType properties:@{NSImageCompressionFactor: @([self reviseCompression])}];
	
	// Save our file and let's go
	[imageData writeToFile:path atomically:YES];
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end
