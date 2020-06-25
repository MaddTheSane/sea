#import "AbstractScaleOptions.h"
#import "AspectRatio.h"

@implementation AbstractScaleOptions
@synthesize ignoresMove;
@synthesize aspectType;

- (instancetype)init
{
	self = [super init];
	if(self){
		aspectType = SeaAspectTypeNone;
		ignoresMove = NO;
	}
	return self;
}


- (void)updateModifiers:(NSEventModifierFlags)modifiers
{
	[super updateModifiers:modifiers];

	if ([super modifier] == AbstractModifierShift) {
		aspectType = SeaAspectTypeRatio;
	} else {
		aspectType = SeaAspectTypeNone;
	}
}

- (NSSize)ratio
{
	if (aspectType == SeaAspectTypeRatio) {
		return NSMakeSize(1, 1);
	}
	return NSZeroSize;
}

@end
