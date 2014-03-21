#import "Bitmap.h"
#import "CIPixellateClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation CIPixellateClass
@synthesize panel;
@synthesize seaPlugins;
@synthesize nibArray;
@synthesize centerBased;
@synthesize scale;

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		NSArray *tmpArray;
		self.seaPlugins = manager;
		[gOurBundle loadNibNamed:@"CIPixellate" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Pixellate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"CIPixellate.scale"])
		self.scale = [defaults floatForKey:@"CIPixellate.scale"];
	else
		scale = 8;
	
	if ([defaults objectForKey:@"CIPixellate.centerBased"])
		self.centerBased = [defaults boolForKey:@"CIPixellate.centerBased"];
	else
		self.centerBased = YES;
	
	if (scale < 1 || scale > 100)
		scale = 8;
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)scale]];
	
	[scaleSlider setIntegerValue:scale];

	[typeRadios setState:scale atRow:0 column:(centerBased) ? 1 : 0];
	
	refresh = YES;
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
		
	[defaults setInteger:scale forKey:@"CIPixellate.scale"];
	[defaults setObject:(centerBased) ? @"YES" : @"NO" forKey:@"CIPixellate.scale"];
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
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	[pluginData cancel];
	if (newdata) { free(newdata); newdata = NULL; }
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	scale = [scaleSlider intValue];
	centerBased = ([typeRadios selectedColumn] == 1);
	[panel setAlphaValue:1.0];
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)scale]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		pluginData = [seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

#define CLASSMETHOD pixellate
#include "CICommon.mi"

- (unsigned char *)pixellate:(PluginData *)pluginData withBitmap:(unsigned char *)data
{
	CIContext *context;
	CIImage *input, *crop_output, *output, *imm_output, *background;
	CIFilter *filter;
	CGImageRef temp_image;
	CGSize size;
	CGRect rect;
	int width, height;
	unsigned char *resdata;
	BOOL opaque = ![pluginData hasAlpha];
	CIColor *backColor;
	IntRect selection;
	
	if (opaque)
		backColor = [[CIColor alloc] initWithColor:[pluginData backColor:YES]];
	
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
	filter = [CIFilter filterWithName:@"CIPixellate"];
	if (filter == NULL) {
		@throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPixellate"] userInfo:NULL];
	}
	[filter setDefaults];
	[filter setValue:input forKey:@"inputImage"];
	[filter setValue:@(scale) forKey:@"inputScale"];
	if (centerBased)
		[filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
	else
		[filter setValue:[CIVector vectorWithX:scale Y:height - scale] forKey:@"inputCenter"];
	imm_output = [filter valueForKey: @"outputImage"];
	
	// Add opaque background (if required)
	if (opaque) {
		filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[filter setDefaults];
		[filter setValue:backColor forKey:@"inputColor"];
		background = [filter valueForKey: @"outputImage"]; 
		filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
		[filter setDefaults];
		[filter setValue:background forKey:@"inputBackgroundImage"];
		[filter setValue:imm_output forKey:@"inputImage"];
		output = [filter valueForKey:@"outputImage"];
	}
	else {
		output = imm_output;
	}
	
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
		
	}
	else {
	
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
		
	return resdata;
}

- (void)finishing
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace, newPixel[4];
	NSInteger pos, i, j, k, i2, j2;
	int width, height, spp, channel;
	int total[4], n, x_stblk, x_endblk, y_stblk, y_endblk;
	int loop;
	
	if (centerBased) return;
	
	pluginData = [seaPlugins data];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	height = [pluginData height];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (loop = 0; loop < 2; loop++) {
	
		if (loop == 0) {
		
			if ((selection.origin.x + selection.size.width) % scale != 0) {
				x_stblk = (selection.origin.x + selection.size.width) / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + 1;
				y_stblk = selection.origin.y / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + ((selection.origin.y + selection.size.height) % scale != 0);
			}
			else {
				continue;
			}
		
		}
		else {
		
			if ((selection.origin.y + selection.size.height) % scale != 0) {
				x_stblk = selection.origin.x / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + ((selection.origin.x + selection.size.width) % scale != 0);
				y_stblk = (selection.origin.y + selection.size.height) / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + 1;
			}
			else {
				continue;
			}
			
		}
		
		for (j = y_stblk; j < y_endblk; j++) {
			for (i = x_stblk; i < x_endblk; i++) {
			
				// Sum and count the present pixels in the  block
				total[0] = total[1] = total[2] = total[3] = 0;
				n = 0;
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								total[k] += data[pos * spp + k];
							}
							n++;
						}
					}
				}
				
				// Determine the revised pixel
				switch (channel) {
					case kAllChannels:
						for (k = 0; k < spp; k++) {
							newPixel[k] = total[k] / n;
						}
					break;
					case kPrimaryChannels:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[k] / n;
						}
						newPixel[spp - 1] = 255;
					break;
					case kAlphaChannel:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[spp - 1] / n;
						}
						newPixel[spp - 1] = 255;
					break;
				}
				
				// Fill the block with this pixel
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						pos = (j * scale + j2) * width + (i * scale + i2);
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								overlay[pos * spp + k] = newPixel[k];
							}
							replace[pos] = 255;
						}
					}
				}
				
			}
		}
		
	}
}


- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
