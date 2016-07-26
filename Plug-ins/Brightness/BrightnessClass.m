#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "BrightnessClass.h"
#import "PluginData.h"
#import "SeaWhiteboard.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation BrightnessClass
@synthesize brightness;
@synthesize contrast;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"Brightness" owner:self topLevelObjects:&tmpArray];
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Brightness and Contrast" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;

	refresh = NO;
	
	self.brightness = self.contrast = 0.0;
	
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
	
	if (refresh)
		[self adjust];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window])
		[NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[self adjust];
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
		[self adjust];
	[pluginData preview];
	refresh = NO;
}

- (void)adjust
{
	PluginData *pluginData;
	IntRect selection;
	int spp, i, j, k, width, channel, pos;
	unsigned char *data, *overlay, *replace;
	float nvalue, value;
	double power;
	
	pluginData = [self.seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	selection = [pluginData selection];
	channel = [pluginData channel];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			for (k = 0; k < spp; k++) {
				
				pos = (j * width + i) * spp + k;
				
				if ((channel == kPrimaryChannels || channel == kAlphaChannel) && k == spp - 1) {
					overlay[pos] = 255;
					
				} else if (channel == kAllChannels && k == spp - 1) {
					
					overlay[pos] = data[pos];
				} else if (channel == kAlphaChannel && k > 0) {
					overlay[pos] = overlay[pos - k];
				} else {
					if (channel == kAlphaChannel)
						value = data[(j * width + i + 1) * spp - 1] / 255.0;
					else
						value = data[pos] / 255.0;
					
					if (brightness < 0.0)
						value = value * (1.0 + brightness);
					else
						value = value + ((1.0 - value) * brightness);
					
					if (contrast < 0.0) {
						if (value > 0.5)
							nvalue = 1.0 - value;
						else
							nvalue = value;
						
						if (nvalue < 0.0)
							nvalue = 0.0;
						
						nvalue = 0.5 * pow (nvalue * 2.0 , (double) (1.0 + contrast));
						
						if (value > 0.5)
							value = 1.0 - nvalue;
						else
							value = nvalue;
					} else {
						if (value > 0.5)
							nvalue = 1.0 - value;
						else
							nvalue = value;
						
						if (nvalue < 0.0)
							nvalue = 0.0;
						
						power = (contrast == 1.0) ? 127 : 1.0 / (1.0 - contrast);
						nvalue = 0.5 * pow (2.0 * nvalue, power);
						
						if (value > 0.5)
							value = 1.0 - nvalue;
						else
							value = nvalue;
					}
					
					overlay[pos] = value * 255.0;
					
				}
			}
			
			replace[j * width + i] = 255;
		}
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
