//
//  SSKCIPlugin.m
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import "SSKCIPlugin.h"
#import "Bitmap.h"
#include <simd/simd.h>

#if defined(__i386__) || defined(__x86_64__)
typedef __m128i simd_type;
#else
typedef simd_uint4 simd_type;
#endif

@implementation SSKCIPlugin

- (SeaPluginType)type
{
	return SeaPluginPoint;
}

- (int)points
{
	return 2;
}

- (void)run
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[self determineContentBorders:pluginData];
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	[self execute];
	[pluginData apply];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	success = YES;
}

- (BOOL)restoreAlpha
{
	return NO;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
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
	SeaPremultiplyBitmap(4, newdata, data, width * height);
	// Convert from RGBA to ARGB
	vdata = (simd_type *)newdata;
	for (size_t i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
		__m128i vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
#else
		simd_uint4 vstore = vdata[i] >> 24;
		vdata[i] = vdata[i] << 8;
		vdata[i] = vdata[i] + vstore;
#endif
	}
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	@try {
		resdata = [self executeChannel:pluginData withBitmap:newdata];
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
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		SeaUnpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	} else {
		SeaUnpremultiplyBitmap(4, resdata, resdata, width * height);
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

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	NSAssert(NO, @"This should be subclassed");
	return NULL;
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	size_t vec_len;
	int width, height, channel;
	unsigned char *resdata, *datatouse;
	IntRect selection;
	simd_type *vdata, *nvdata, *rvdata;
#if defined(__i386__) || defined(__x86_64__)
	__m128i orvmask;
	{
		unsigned char ormask[16];
		for (short i = 0; i < 16; i++) {
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
	vdata = (simd_type *)data;
	if ([self restoreAlpha]) {
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) {
			vec_len /= 16;
		} else {
			vec_len /= 16;
			vec_len++;
		}
		nvdata = (simd_type *)newdata;
		datatouse = newdata;
		if (channel == SeaSelectedChannelAlpha) {
			for (size_t i = 0; i < width * height; i++) {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			}
		} else {
			for (int i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
				nvdata[i] = _mm_or_si128(vdata[i], orvmask);
#else
				nvdata[i] = vdata[i] | orvmask;
#endif
			}
		}
	} else {
		if (channel == SeaSelectedChannelPrimary || channel == SeaSelectedChannelAlpha) {
			width = [pluginData width];
			height = [pluginData height];
			vec_len = width * height * 4;
			if (vec_len % 16 == 0) {
				vec_len /= 16;
			} else {
				vec_len /= 16;
				vec_len++;
			}
			rvdata = (simd_type *)newdata;
			datatouse = newdata;
			if (channel == SeaSelectedChannelPrimary) {
				for (int i = 0; i < vec_len; i++) {
#if defined(__i386__) || defined(__x86_64__)
					rvdata[i] = _mm_or_si128(vdata[i], orvmask);
#else
					rvdata[i] = vdata[i] | orvmask;
#endif
				}
			} else if (channel == SeaSelectedChannelAlpha) {
				for (int i = 0; i < width * height; i++) {
					newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
					newdata[i * 4] = 255;
				}
			}
		}
	}
	
	// Run CoreImage effect
	resdata = [self coreImageEffect:pluginData withBitmap:datatouse];
	
	if ([self restoreAlpha]) {
		// Restore alpha
		if (channel == SeaSelectedChannelAll) {
			for (int i = 0; i < selection.size.height; i++) {
				for(int j = 0; j < selection.size.width; j++){
					resdata[(i * selection.size.width + j) * 4 + 3] =
					data[(width * (i + selection.origin.y) +
						  j + selection.origin.x) * 4];
				}
			}
		}
	}
	
	return resdata;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if (refresh)
		[self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[pluginData cancel];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[pluginData.window endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:sender];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	[self savePluginPreferences];
	
	if (refresh)
		[self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window])
		[[pluginData window] endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
