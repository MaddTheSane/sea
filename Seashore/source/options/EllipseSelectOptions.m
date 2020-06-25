#import "EllipseSelectOptions.h"
#import "AspectRatio.h"

@implementation EllipseSelectOptions

- (void)awakeFromNib
{	
	[aspectRatio awakeWithMaster:self andString:@"ell"];
}

- (NSSize)ratio
{
	return [aspectRatio ratio];
}

- (SeaAspectType)aspectType
{
	return [aspectRatio aspectType];
}

- (void)shutdown
{
	[aspectRatio shutdown];
}

@end
