#include <GIMPCore/GIMPCore.h>
#include <math.h>
#include <tgmath.h>
#import "ThresholdView.h"
#import "ThresholdClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation ThresholdClass
@synthesize bottomValue;
@synthesize topValue;
@synthesize rangeLabel;
@synthesize view;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		NSArray *tmpArray;
		self.seaPlugins = manager;
		[gOurBundle loadNibNamed:@"Threshold" owner:self topLevelObjects:&tmpArray];
		self.nibArray = tmpArray;
	}
	
	return self;
}

- (SeaPluginType)type
{
	return SeaPluginBasic;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Threshold" table:NULL];
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

	refresh = YES;
	
	self.topValue = 0;
	self.bottomValue = 255;
	
	[rangeLabel setStringValue:[NSString stringWithFormat:@"%ld - %ld", (long)topValue, (long)bottomValue]];
	
	[view calculateHistogram:pluginData];
	
	success = NO;
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
	if ([pluginData window]) [NSApp endSheet:panel];
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

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	if (topValue < bottomValue)
		[rangeLabel setStringValue:[NSString stringWithFormat:@"%ld - %ld", (long)topValue, (long)bottomValue]];
	else
		[rangeLabel setStringValue:[NSString stringWithFormat:@"%ld - %ld", (long)bottomValue, (long)topValue]];
	
	[panel setAlphaValue:1.0];
	refresh = YES;
	
	[view setNeedsDisplay:YES];
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

- (void)adjust
{
	PluginData *pluginData = [self.seaPlugins data];
	IntRect selection;
	int i, j, k, spp, width, channel, mid;
	unsigned char *data, *overlay, *replace;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:SeaOverlayBehaviourReplacing];
	
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			if (channel == SeaSelectedChannelAll || channel == SeaSelectedChannelPrimary) {
				mid = 0;
				for (k = 0; k < spp - 1; k++)
					mid += data[(j * width + i) * spp + k];
				mid /= (spp - 1);
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = data[(j * width + i + 1) * spp - 1];
				
				replace[j * width + i] = 255;
			} else if (channel == SeaSelectedChannelAlpha) {
				mid = data[(j * width + i + 1) * spp - 1];
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = 255;
				
				replace[j * width + i] = 255;
			}
		}
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
