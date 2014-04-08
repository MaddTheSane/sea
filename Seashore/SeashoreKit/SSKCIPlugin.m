//
//  SSKCIPlugin.m
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import "SSKCIPlugin.h"
#import "Bitmap.h"

@implementation SSKCIPlugin

- (id)initWithManager:(SeaPlugins *)manager
{
	return self = [super initWithManager:manager];
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (void)run
{
	PluginData *pluginData = [seaPlugins data];
	
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
	PluginData *pluginData = [seaPlugins data];
	
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
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
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
	dispatch_apply(width * height, dispatch_get_global_queue(0, 0), ^(size_t i) {
		newdata[i * 4] = data[i * 2 + 1];
		newdata[i * 4 + 1] = data[i * 2];
		newdata[i * 4 + 2] = data[i * 2];
		newdata[i * 4 + 3] = data[i * 2];
	});
	
	// Run CoreImage effect
	resdata = [self executeChannel:pluginData withBitmap:newdata];
	
	// Convert from output to GA
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height))
		max = selection.size.width * selection.size.height;
	else
		max = width * height;
	dispatch_apply(max, dispatch_get_global_queue(0, 0), ^(size_t i) {
		newdata[i * 2] = resdata[i * 4];
		newdata[i * 2 + 1] = resdata[i * 4 + 3];
	});
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		dispatch_apply(selection.size.height, dispatch_get_global_queue(0, 0), ^(size_t i) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[selection.size.width * 2 * i]), selection.size.width * 2);
		});
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, newdata, width * height * 2);
	}
}

- (void)executeColor:(PluginData *)pluginData
{
	__m128i *vdata;
	IntRect selection;
	int width, height;
	unsigned char *data, *resdata, *overlay, *replace;
	size_t vec_len;
	
	// Set-up plug-in
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
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
	premultiplyBitmap(4, newdata, data, width * height);
	// Convert from RGBA to ARGB
	vdata = (__m128i *)newdata;
	dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
		__m128i vstore = _mm_srli_epi32(vdata[i], 24);
		vdata[i] = _mm_slli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	});
	
	// Run CoreImage effect (exception handling is essential because we've altered the image data)
	@try {
		resdata = [self executeChannel:pluginData withBitmap:newdata];
	}
	@catch (NSException *exception) {
		dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
			__m128i vstore = _mm_slli_epi32(vdata[i], 24);
			vdata[i] = _mm_srli_epi32(vdata[i], 8);
			vdata[i] = _mm_add_epi32(vdata[i], vstore);
		});
		NSLog(@"%@", [exception reason]);
		return;
	}
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		unpremultiplyBitmap(4, resdata, resdata, selection.size.width * selection.size.height);
	} else {
		unpremultiplyBitmap(4, resdata, resdata, width * height);
	}
	// Convert from ARGB to RGBA
	dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
		__m128i vstore = _mm_slli_epi32(vdata[i], 24);
		vdata[i] = _mm_srli_epi32(vdata[i], 8);
		vdata[i] = _mm_add_epi32(vdata[i], vstore);
	});
	
	// Copy to destination
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		dispatch_apply(selection.size.height, dispatch_get_global_queue(0, 0), ^(size_t i) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 4]), &(resdata[selection.size.width * 4 * i]), selection.size.width * 4);
		});
	} else {
		memset(replace, 0xFF, width * height);
		memcpy(overlay, resdata, width * height * 4);
	}
}

- (unsigned char *)coreImageEffect:(PluginData *)pluginData withBitmap:(unsigned char *)data
{

	return NULL;
}

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	size_t vec_len;
	int width, height, channel;
	unsigned char ormask[16], *resdata, *datatouse;
	IntRect selection;
	__m128i *vdata, *nvdata, *rvdata, orvmask;
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	vdata = (__m128i *)data;
	if ([self restoreAlpha]) {
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) {
			vec_len /= 16;
		} else {
			vec_len /= 16;
			vec_len++;
		}
		nvdata = (__m128i *)newdata;
		datatouse = newdata;
		if (channel == kAlphaChannel) {
			dispatch_apply(width * height, dispatch_get_global_queue(0, 0), ^(size_t i) {
				newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
				newdata[i * 4] = 255;
			});
		} else {
			for (short i = 0; i < 16; i++) {
				ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
			}
			memcpy(&orvmask, ormask, 16);
			dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
				nvdata[i] = _mm_or_si128(vdata[i], orvmask);
			});
		}
	} else {
		if (channel == kPrimaryChannels || channel == kAlphaChannel) {
			width = [pluginData width];
			height = [pluginData height];
			vec_len = width * height * 4;
			if (vec_len % 16 == 0) {
				vec_len /= 16;
			} else {
				vec_len /= 16;
				vec_len++;
			}
			rvdata = (__m128i *)newdata;
			datatouse = newdata;
			if (channel == kPrimaryChannels) {
				for (short i = 0; i < 16; i++) {
					ormask[i] = (i % 4 == 0) ? 0xFF : 0x00;
				}
				memcpy(&orvmask, ormask, 16);
				dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
					rvdata[i] = _mm_or_si128(vdata[i], orvmask);
				});
			} else if (channel == kAlphaChannel) {
				dispatch_apply(width * height, dispatch_get_global_queue(0, 0), ^(size_t i) {
					newdata[i * 4 + 1] = newdata[i * 4 + 2] = newdata[i * 4 + 3] = data[i * 4];
					newdata[i * 4] = 255;
				});
			}
		}
	}
	
	// Run CoreImage effect
	resdata = [self coreImageEffect:pluginData withBitmap:datatouse];
	
	if ([self restoreAlpha]) {
		// Restore alpha
		if (channel == kAllChannels) {
			dispatch_apply(selection.size.height, dispatch_get_global_queue(0, 0), ^(size_t i) {
				for(int j = 0; j < selection.size.width; j++){
					resdata[(i * selection.size.width + j) * 4 + 3] =
					data[(width * (i + selection.origin.y) +
						  j + selection.origin.x) * 4];
				}
			});
		}
	}
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
