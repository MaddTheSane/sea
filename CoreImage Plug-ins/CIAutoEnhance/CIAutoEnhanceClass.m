#import "CIAutoEnhanceClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIAutoEnhanceClass

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		seaPlugins = manager;
	}
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Median" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Enhance" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	pluginData = [seaPlugins data];
	[self execute];
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return success;
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    CIImage *myImage = SeaCreateCIImage(pluginData);
    
    NSArray *adjustments = [myImage autoAdjustmentFilters];
    for (CIFilter *filter in adjustments) {
        [filter setValue:myImage forKey:kCIInputImageKey];
        myImage = filter.outputImage;
    }
    
    SeaRenderCIImage(pluginData,myImage);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
