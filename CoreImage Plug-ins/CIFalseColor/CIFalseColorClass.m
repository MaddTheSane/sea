#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#include <simd/simd.h>
#import "CIFalseColorClass.h"

#if defined(__i386__) || defined(__x86_64__)
typedef __m128i simd_type;
#else
typedef simd_uint4 simd_type;
#endif

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIFalseColorClass

- (SeaPluginType)type
{
	return SeaPluginBasic;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Color Ramp" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData = [self.seaPlugins data];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return success;
}

- (void)execute
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if ([pluginData spp] == 2) {
		[self executeGrey:pluginData];
	} else {
		[self executeColor:pluginData];
	}
}

- (void)executeGrey:(PluginData *)pluginData
{
	IntRect selection;
	int spp, width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	size_t vec_len, max;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	spp = [pluginData spp];
	vec_len = width * height * spp;
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	// Convert from GA to ARGB
	for (size_t i = 0; i < width * height; i++) {
		newdata[i * 4] = data[i * 2 + 1];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2];
	}
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
	// Convert from output to GA
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
		max = selection.size.width * selection.size.height;
	else
		max = width * height;
	for (size_t i = 0; i < max; i++) {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	}
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (size_t i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(self->newdata[selection.size.width * 2 * i]), selection.size.width * 2);
		}
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
}

- (void)executeColor:(PluginData *)pluginData
{
	simd_type *vdata;
	IntRect selection;
	int width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	size_t vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	// Convert from RGBA to ARGB
	vdata = (simd_type *)data;
	for (size_t i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
		__m128i vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
#else
		simd_uint4 vstore = (vdata[i] >> 24) & 0xFF;
		vdata[i] = (vdata[i] << 8) & 0xFFFFFF00;
		vdata[i] = vdata[i] | vstore;
#endif
	}
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	@try {
		resdata = [self executeChannel:pluginData withBitmap:data];
	}
	@catch (NSException *exception) {
		for (size_t i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
			__m128i vstore = _mm_slli_epi32(vdata[i], 24);
			vdata[i] = _mm_srli_epi32(vdata[i], 8);
			vdata[i] = _mm_add_epi32(vdata[i], vstore);
#else
			simd_uint4 vstore = (vdata[i] << 24) & 0xFF000000;
			vdata[i] = (vdata[i] >> 8) & 0x00FFFFFF;
			vdata[i] = vdata[i] | vstore;
#endif
		}
		NSLog(@"%@", [exception reason]);
		return;
	}
	
	// Convert from ARGB to RGBA
	for (size_t i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
		__m128i vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
#else
		simd_uint4 vstore = (vdata[i] << 24) & 0xFF000000;
		vdata[i] = (vdata[i] >> 8) & 0x00FFFFFF;
		vdata[i] = vdata[i] | vstore;
#endif
	}
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		for (size_t i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		}
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	int i, j, vec_len, width, height, channel;
	IntRect selection;
	unsigned char *resdata, *datatouse;
	simd_type *vdata, *nvdata;
#if defined(__i386__) || defined(__x86_64__)
	__m128i orvmask;
	{
		unsigned char ormask[16];
		for (i = 0; i < 16; i++) {
			ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
		}
		memcpy(&orvmask, ormask, 16);
	}
#else
	const simd_uint4 orvmask = simd_make_uint4(255, 255, 255, 255);
#endif
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	vec_len = width * height * 4;
	if (vec_len % 16 == 0) {
		vec_len /= 16;
	} else {
		vec_len /= 16;
		vec_len++;
	}
	vdata = (simd_type *)data;
	nvdata = (simd_type *)newdata;
	datatouse = newdata;
	if (channel == SeaSelectedChannelAlpha) {
		for (size_t i = 0; i < vec_len; i++) {
			newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
			newdata[i * 4] = 255;
		}
	} else {
		for (size_t i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
			nvdata[i] = _mm_or_si128(vdata[i], orvmask);
#else
			nvdata[i] = vdata[i] | orvmask;
#endif
		}
	}
	
	// Run CoreImage effect
	resdata = [self whitePointAdjust:pluginData withBitmap:datatouse];
	
	// Restore alpha
	if (channel == SeaSelectedChannelAll) {
		for (i = 0; i < selection.size.height; i++) {
			for(j = 0; j < selection.size.width; j++){
				resdata[(i * selection.size.width + j) * 4 + 3] =
				data[(width * (i + selection.origin.y) +
					  j + selection.origin.x) * 4];
			}
		}
	}
	
	return resdata;
}

- (unsigned char *)whitePointAdjust:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *output;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	NSColor *foreNSColor, *backNSColor;
	CIColor *foreColor, *backColor;
	IntRect selection;
	
	// Find colors
	foreNSColor = [pluginData foreColor:YES];
	foreColor = [[CIColor alloc] initWithColor:foreNSColor];
	backNSColor = [pluginData backColor:YES];
	backColor = [[CIColor alloc] initWithColor:backNSColor];
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Create core image with data
	size.width = width;
	size.height = height;
	input = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIFalseColor"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIFalseColor"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:kCIInputImageKey];
	[filter setValue:foreColor forKey:@"inputColor0"];
	[filter setValue:backColor forKey:@"inputColor1"];
	output = [filter valueForKey: kCIOutputImageKey];
	
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:kCIInputImageKey];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:kCIOutputImageKey];
		
		// Create output core image
		rect.origin.x = selection.origin.x;
		rect.origin.y = height - selection.size.height - selection.origin.y;
		rect.size.width = selection.size.width;
		rect.size.height = selection.size.height;
		temp_image = [context createCGImage:output fromRect:rect];
	} else {
		// Create output core image
		rect.origin.x = 0;
		rect.origin.y = 0;
		rect.size.width = width;
		rect.size.height = height;
		temp_image = [context createCGImage:output fromRect:rect];
	}
	
	// Get data from output core image
	temp_rep = [[NSBitmapImageRep alloc] initWithCGImage:temp_image];
	CGImageRelease(temp_image);
	resdata = [temp_rep bitmapData];
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
