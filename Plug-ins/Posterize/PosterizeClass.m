#import "PosterizeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation PosterizeClass
@synthesize posterizeValue = posterize;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super initWithManager:manager]) {
		NSArray *tmpArray;
		[gOurBundle loadNibNamed:@"Posterize" owner:self topLevelObjects:&tmpArray];
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Posterize" table:NULL];
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
	PluginData *pluginData;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults objectForKey:@"Posterize.posterize"])
		self.posterizeValue = [defaults integerForKey:@"Posterize.posterize"];
	else
		self.posterizeValue = 2;
	refresh = YES;
	
	if (posterize < 2 || posterize > 255)
		self.posterizeValue = 1;
	
	refresh = YES;
	
	pluginData = [self.seaPlugins data];
	
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if (refresh)
		[self posterize];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window])
		[NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[defaults setInteger:posterize forKey:@"Posterize.posterize"];
}

- (void)reapply
{
	PluginData *pluginData = [self.seaPlugins data];
	
	[self posterize];
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
		[self posterize];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	[panel setAlphaValue:1.0];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [self.seaPlugins data];
		if ([pluginData window])
			[panel setAlphaValue:0.4];
	}
}

- (void)posterize
{
	PluginData *pluginData = [self.seaPlugins data];
	IntRect selection;
	int i, j, k, spp, width, channel, value;
	unsigned char *data, *overlay, *replace;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			if (channel == kAllChannels || channel == kPrimaryChannels) {
				for (k = 0; k < spp - 1; k++) {
					value = data[(j * width + i) * spp + k];
					value = (float)value * (float)posterize / 255.0;
					value = (float)value * 255.0 / (float)(posterize - 1);
					if (value > 255)
						value = 255;
					if (value < 0)
						value = 0;
					overlay[(j * width + i) * spp +	k] = value;
				}
				overlay[(j * width + i + 1) * spp - 1] = data[(j * width + i + 1) * spp - 1];
				replace[j * width + i] = 255;
			} else if (channel == kAlphaChannel) {
				value = data[(j * width + i + 1) * spp - 1];
				value = (float)value * (float)posterize / 255.0;
				value = (float)value * 255.0 / (float)(posterize - 1);
				if (value > 255)
					value = 255;
				if (value < 0)
					value = 0;
				memset(&(overlay[(j * width + i) * spp]), value, spp - 1);
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
