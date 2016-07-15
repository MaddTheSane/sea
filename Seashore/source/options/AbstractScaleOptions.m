#import "AbstractScaleOptions.h"
#import "AspectRatio.h"

@implementation AbstractScaleOptions
@synthesize ignoresMove;
@synthesize aspectType;

- (instancetype)init
{
	self = [super init];
	if(self){
		aspectType = kNoAspectType;
		ignoresMove = NO;
	}
	return self;
}


- (void)updateModifiers:(NSEventModifierFlags)modifiers
{
	[super updateModifiers:modifiers];

	if ([super modifier] == kShiftModifier) {
		aspectType = kRatioAspectType;
	} else {
		aspectType = kNoAspectType;
	}
}

- (NSSize)ratio
{
	if (aspectType == kRatioAspectType) {
		return NSMakeSize(1, 1);
	}
	return NSZeroSize;
}

@end
