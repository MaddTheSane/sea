//
//  SSKPlugin.m
//  Seashore
//
//  Created by C.W. Betts on 3/20/14.
//
//

#import "SSKPlugin.h"
#define gOurBundle [NSBundle bundleForClass:[self class]]
#define make_128(x) (x + 16 - (x % 16))

@implementation SSKPlugin
@synthesize seaPlugins;

- (instancetype)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		self.seaPlugins = manager;
	}
	
	return self;
}

- (void)savePluginPreferences
{
	
}

- (NSString*)sanity
{
	return @"Nope";
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Checkerboard" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (void)run
{
	NSLog(@"Class %@ does not implement the run method: failing", NSStringFromClass([self class]));
	success = NO;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

- (void)determineContentBorders:(PluginData *)pluginData
{
	// Start out with invalid content borders
	int contentLeft = -1, contentRight = -1, contentTop = -1, contentBottom = -1;
	// Select the appropriate data for working out the content borders
	int width = [pluginData width];
	int height = [pluginData height];
	int spp = [pluginData spp];
	unsigned char *data = [pluginData data];
	int i, j;
	
	// Determine left content margin
	for (i = 0; i < width && contentLeft == -1; i++) {
		for (j = 0; j < height && contentLeft == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentLeft = i;
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && contentRight == -1; i--) {
		for (j = 0; j < height && contentRight == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentRight = i;
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && contentTop == -1; j++) {
		for (i = 0; i < width && contentTop == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentTop = j;
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && contentBottom == -1; j--) {
		for (i = 0; i < width && contentBottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				contentBottom = j;
			}
		}
	}
	
	// Put into bounds
	if (contentLeft != -1 && contentTop != -1 && contentRight != -1 && contentBottom != -1) {
		bounds.origin.x = contentLeft;
		bounds.origin.y = contentTop;
		bounds.size.width = contentRight - contentLeft + 1;
		bounds.size.height = contentBottom - contentTop + 1;
		boundsValid = YES;
	} else {
		boundsValid = NO;
	}
}


@end
