#include <math.h>
#include <tgmath.h>
#import "BlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation BlurClass
{
	NSArray *nibObjs;
}

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		seaPlugins = manager;
		NSArray *tmpNibObjs;
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"Blur" owner:self topLevelObjects:&tmpNibObjs];
		nibObjs = tmpNibObjs;
	}
	
	return self;
}

- (int)type
{
	return kBasicPlugin;
}

-(int)points
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Blur" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"Blur.applications"])
		applications = [gUserDefaults integerForKey:@"Blur.applications"];
	else
		applications = 1;
	refresh = YES;
	
	if (applications < 0 || applications > 100)
		applications = 1;
	
	applicationsLabel.integerValue = applications;
	applicationsSlider.integerValue = applications;
	
	success = NO;
	pluginData = [seaPlugins data];
	if ([pluginData window]) {
		[[pluginData window] beginSheet:panel completionHandler:^(NSModalResponse returnCode) {
			
		}];
	} else
		[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	if (refresh) [self blur];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [pluginData.window endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[gUserDefaults setInteger:applications forKey:@"Blur.applications"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self blur];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self blur];
	[pluginData preview];
	if ([pluginData window]) [panel setAlphaValue:0.4];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[pluginData.window endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	applications = round([applicationsSlider doubleValue]);
	
	applicationsLabel.integerValue = applications;
	[panel setAlphaValue:1.0];
	refresh = YES;
}

- (void)blur
{
	int l, spp, width, channel;
	unsigned char *data, *overlay, *replace, *workpad;
	int numerator, denominator, t;
	
	PluginData *pluginData = [seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	IntRect selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (int j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (int i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			if (channel == kAllChannels) {
				
				denominator = 0;
				l = 0;
				
				for (int k = 0; k < spp - 1; k++) {
					numerator = 0;
					
					for (int x = i - 1; x < i + 2; x++) {
						for (int y = j - 1; y < j + 2; y++) {
							if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
								t = (y * width) + x;
								numerator += data[t * spp + k] * data[(t + 1) * spp - 1];
								if (k == 0) {
									denominator += data[(t + 1) * spp - 1];
									l++;
								}
							}
						}
					}
					
					t = (denominator == 0) ? t = 0 : (int)(round((float)numerator / (float)denominator));
					overlay[((j * width) + i) * spp + k] = t;
					
				}
				
				t = (l == 0) ? t = 0 : (int)(round((float)denominator / (float)l));
				overlay[((j * width) + i + 1) * spp - 1] = t;
				replace[(j * width) + i] = 255;
			} else if (channel == kPrimaryChannels) {
				for (int k = 0; k < spp - 1; k++) {
					numerator = 0;
					denominator = 0;
					
					for (int x = i - 1; x < i + 2; x++) {
						for (int y = j - 1; y < j + 2; y++) {
							if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
								t = (y * width) + x;
								numerator += data[t * spp + k];
								denominator++;
							}
						}
					}
					
					t = (int)(round((float)numerator / (float)denominator));
					overlay[((j * width) + i) * spp + k] = t;
				}
				
				overlay[((j * width) + i + 1) * spp - 1] = 255;
				replace[(j * width) + i] = 255;
			} else if (channel == kAlphaChannel) {
				numerator = 0;
				denominator = 0;
				
				for (int x = i - 1; x < i + 2; x++) {
					for (int y = j - 1; y < j + 2; y++) {
						if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
							t = (y * width) + x;
							numerator += data[(t + 1) * spp - 1];
							denominator++;
						}
					}
				}
				
				t = (int)(round((float)numerator / (float)denominator));
				for (int k = 0; k < spp - 1; k++) {
					overlay[((j * width) + i) * spp + k] = t;
				}
				
				overlay[((j * width) + i + 1) * spp - 1] = 255;
				replace[(j * width) + i] = 255;
				
			}
			
		}
	}
	
	if (applications > 1) {
		workpad = malloc(selection.size.width * selection.size.height * spp);
		
		for (int count = 1; count < applications; count++) {
			for (int j = 0; j < selection.size.height; j++) {
				memcpy(&(workpad[j * selection.size.width * spp]), &(overlay[((j + selection.origin.y) * width + selection.origin.x) * spp]), selection.size.width * spp);
			}
			
			for (int j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
				for (int i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
					if (channel == kAllChannels) {
						
						denominator = 0;
						l = 0;
						
						for (int k = 0; k < spp - 1; k++) {
							numerator = 0;
							
							for (int x = i - 1; x < i + 2; x++) {
								for (int y = j - 1; y < j + 2; y++) {
									if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
										t = ((y - selection.origin.y) * selection.size.width) + (x - selection.origin.x);
										numerator += workpad[t * spp + k] * workpad[(t + 1) * spp - 1];
										if (k == 0) {
											denominator += workpad[(t + 1) * spp - 1];
											l++;
										}
									}
								}
							}
							
							t = (denominator == 0) ? t = 0 : (int)(round((float)numerator / (float)denominator));
							overlay[((j * width) + i) * spp + k] = t;
							
						}
						
						t = (l == 0) ? t = 0 : (int)(round((float)denominator / (float)l));
						overlay[((j * width) + i + 1) * spp - 1] = t;
						replace[(j * width) + i] = 255;
						
					} else if (channel == kPrimaryChannels) {
						for (int k = 0; k < spp - 1; k++) {
							numerator = 0;
							denominator = 0;
							
							for (int x = i - 1 - selection.origin.x; x < i - selection.origin.x + 2; x++) {
								for (int y = j - 1 - selection.origin.y; y < j - selection.origin.y + 2; y++) {
									if (x >= 0 && y >= 0  && x < selection.size.width && y < selection.size.height) {
										t = ((y - selection.origin.y) * selection.size.width) + (x - selection.origin.x);
										numerator += workpad[t * spp + k];
										denominator++;
									}
								}
							}
							
							t = (int)(round((float)numerator / (float)denominator));
							overlay[((j * width) + i) * spp + k] = t;
						}
					} else if (channel == kAlphaChannel) {
						numerator = 0;
						denominator = 0;
						
						for (int x = i - 1 - selection.origin.x; x < i - selection.origin.x + 2; x++) {
							for (int y = j - 1 - selection.origin.y; y < j - selection.origin.y + 2; y++) {
								if (x >= 0 && y >= 0  && x < selection.size.width && y < selection.size.height) {
									t = ((y - selection.origin.y) * selection.size.width) + (x - selection.origin.x);
									numerator += workpad[t * spp];
									denominator++;
								}
							}
						}
						
						t = (int)(round((float)numerator / (float)denominator));
						for (int k = 0; k < spp - 1; k++) {
							overlay[((j * width) + i) * spp + k] = t;
						}
						
					}
				}
			}
		}
		
		free(workpad);
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
