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

- (id)initWithManager:(SeaPlugins *)manager
{
	if (self = [super init]) {
		self.seaPlugins = manager;
	}
	
	return self;
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

@end
