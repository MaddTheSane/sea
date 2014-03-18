#import "Bitmap.h"
#import "CIGaussianBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIGaussianBlurClass
@synthesize seaPlugins;
@synthesize panel;
@synthesize radius;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		self.seaPlugins = manager;
		[NSBundle loadNibNamed:@"CIGaussianBlur" owner:self];
	}
	
	return self;
}


- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gaussian Blur" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Blur" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"CIGaussianBlur.radius"])
		radius = [defaults integerForKey:@"CIGaussianBlur.radius"];
	else
		radius = 10;
	refresh = YES;
	
	if (radius < 1 || radius > 100)
		radius = 10;
	
	success = NO;
	pluginData = [seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData = [seaPlugins data];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (refresh)
		[self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	if (newdata) { free(newdata); newdata = NULL; }
		
	[defaults setInteger:radius forKey:@"CIGaussianBlur.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	//if ([pluginData spp] == 2 || [pluginData channel] != kAllChannels){
	newdata = malloc(make_128([pluginData width] * [pluginData height] * 4));
	//}
	[self execute];
	[pluginData apply];
	if (newdata) { free(newdata); newdata = NULL; }
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	if (refresh)
		[self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	[pluginData cancel];
	if (newdata) {
		free(newdata);
		newdata = NULL;
	}
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
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
	int i, spp, width, height;
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
	
	// Convert output to GA
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
		for (i = 0; i < selection.size.height; i++) {
			memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
			memcpy(&(overlay[(width * (selection.origin.y + i) + selection.origin.x) * 2]), &(newdata[selection.size.width * 2 * i]), selection.size.width * 2);
		}
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
	}else {
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

- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	int i, vec_len, width, height, channel;
	unsigned char ormask[16], *resdata, *datatouse;
	__m128i *vdata, *rvdata, orvmask;
	
	// Make adjustments for the channel
	channel = [pluginData channel];
	datatouse = data;
	if (channel == kPrimaryChannels || channel == kAlphaChannel) {
		width = [pluginData width];
		height = [pluginData height];
		vec_len = width * height * 4;
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		vdata = (__m128i *)data;
		rvdata = (__m128i *)newdata;
		datatouse = newdata;
		if (channel == kPrimaryChannels) {
			for (i = 0; i < 16; i++) {
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
	
	// Run CoreImage effect
	resdata = [self blur:pluginData withBitmap:datatouse];
	
	return resdata;
}

- (unsigned char *)blur:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *unclampedInput, *clampedInput, *crop_output, *output;
	CIFilter *clamp, *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	size_t i, vec_len;
	int width, height;
	unsigned char *resdata;
	BOOL opaque, done;
	IntRect selection;
	unsigned char ormask[16];
	__m128i *vresdata, orvmask;
	
	// Find core image context
	context = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:@{kCIContextWorkingColorSpace: (id)[pluginData displayProf], kCIContextOutputColorSpace: (id)[pluginData displayProf]}];
	
	// Get plug-in data
	width = [pluginData width];
	height = [pluginData height];
	selection = [pluginData selection];
	
	// Check if image is opaque
	opaque = ![pluginData hasAlpha] || ([pluginData channel] != kAllChannels);
	if (opaque == NO) {
		done = NO;
		for (i = 0; i < width * height && !done; i++) {
			if (data[i * 4] != 0xFF)
				done = YES;
		}
		if (done == NO) {
			opaque = YES;
		}
	}
	
	// Create core image with data
	size.width = width;
	size.height = height;
	unclampedInput = [CIImage imageWithBitmapData:[NSData dataWithBytesNoCopy:data length:width * height * 4 freeWhenDone:NO] bytesPerRow:width * 4 size:size format:kCIFormatARGB8 colorSpace:[pluginData displayProf]];
	
	// We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
	// the content outside the borders of the image
	clamp = [CIFilter filterWithName: @"CIAffineClamp"];
	[clamp setDefaults];
	[clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
	[clamp setValue:unclampedInput forKey: @"inputImage"];
	clampedInput = [clamp valueForKey: @"outputImage"];
	
	// Run filter
	filter = [CIFilter filterWithName:@"CIGaussianBlur"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGaussianBlur"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:clampedInput forKey:@"inputImage"];
	[filter setValue:@(radius) forKey:@"inputRadius"];
	output = [filter valueForKey:@"outputImage"];
	
	if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
		// Crop to selection
		filter = [CIFilter filterWithName:@"CICrop"];
		[filter setDefaults];
		[filter setValue:output forKey:@"inputImage"];
		[filter setValue:[CIVector vectorWithX:selection.origin.x Y:height - selection.size.height - selection.origin.y Z:selection.size.width W:selection.size.height] forKey:@"inputRectangle"];
		crop_output = [filter valueForKey:@"outputImage"];
		
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
	temp_rep = [NSBitmapImageRep imageRepWithData:[[[NSBitmapImageRep alloc] initWithCGImage:temp_image] TIFFRepresentation]];
	CGImageRelease(temp_image);
	resdata = [temp_rep bitmapData];
	
	// Handle opaque images
	if (opaque) {
		vec_len = [temp_rep pixelsWide] * [temp_rep pixelsHigh] * [temp_rep samplesPerPixel];
		if (vec_len % 16 == 0) { vec_len /= 16; }
		else { vec_len /= 16; vec_len++; }
		for (i = 0; i < 16; i++) {
			ormask[i] = (i % 4 == 3) ? 0xFF : 0x00;
		}
		memcpy(&orvmask, ormask, 16);
		vresdata = (__m128i *)resdata;
		dispatch_apply(vec_len, dispatch_get_global_queue(0, 0), ^(size_t i) {
			vresdata[i] = _mm_or_si128(vresdata[i], orvmask);
		});
	}
	
	return resdata;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
