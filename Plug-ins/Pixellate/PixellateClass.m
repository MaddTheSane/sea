#include <GIMPCore/GIMPCore.h>
#import "PixellateClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation PixellateClass
@synthesize scale;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"Pixellate" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (int)type
{
	return kBasicPlugin;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Pixellate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylise" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"Pixellate.scale"])
		self.scale = [defaults integerForKey:@"Pixellate.scale"];
	else
		self.scale = 8;
		
	if (scale < 0 || scale > 100)
		self.scale = 8;
	
	refresh = YES;
	success = NO;
	pluginData = [self.seaPlugins data];
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (refresh)
		[self pixellate];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window])
		[NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[defaults setInteger:scale forKey:@"Pixellate.scale"];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	if (refresh)
		[self pixellate];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[pluginData cancel];
	
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
		[self preview:sender];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

- (void)pixellate
{
	PluginData *pluginData = [self.seaPlugins data];
	IntRect selection;
	unsigned char *data, *overlay, *replace, newPixel[4];
	NSInteger pos, i, j, k, i2, j2;
	int width, height, spp, channel;
	int total[4], n = 1, x_stblk, x_endblk, y_stblk, y_endblk;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	height = [pluginData height];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	x_stblk = selection.origin.x / scale;
	x_endblk = (selection.origin.x + selection.size.width) / scale + ((selection.origin.x + selection.size.width) % scale != 0);
	y_stblk = selection.origin.y / scale;
	y_endblk = (selection.origin.y + selection.size.height) / scale + ((selection.origin.y + selection.size.height) % scale != 0);
	
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
				case SeaSelectedChannelAll:
					for (k = 0; k < spp; k++) {
						newPixel[k] = total[k] / n;
					}
					break;
				case SeaSelectedChannelPrimary:
					for (k = 0; k < spp - 1; k++) {
						newPixel[k] = total[k] / n;
					}
					newPixel[spp - 1] = 255;
					break;
				case SeaSelectedChannelAlpha:
					for (k = 0; k < spp - 1; k++) {
						newPixel[k] = total[spp - 1] / n;
					}
					newPixel[spp - 1] = 255;
					break;
			}
			
			// Fill the block with this pixel
			for (j2 = 0; j2 < scale; j2++) {
				for (i2 = 0; i2 < scale; i2++) {
					//pos = (j * scale + j2) * width + (i * scale + i2);
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

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
