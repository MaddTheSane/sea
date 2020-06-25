//
//  SSKVisualPlugin.m
//  Seashore
//
//  Created by C.W. Betts on 4/8/14.
//
//

#import "SSKVisualPlugin.h"

@implementation SSKVisualPlugin
@synthesize panel;

- (IBAction)preview:(id)sender
{
	
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

@end
