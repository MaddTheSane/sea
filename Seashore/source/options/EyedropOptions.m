#import "EyedropOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaController.h"
#import "SeaTools.h"

@implementation EyedropOptions

- (void)awakeFromNib
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"eyedrop size"] == NULL) {
		value = 1;
	}
	else {
		value = [defaults integerForKey:@"eyedrop size"];
		if (value < [sizeSlider minValue] || value > [sizeSlider maxValue])
			value = 1;
	}
	[sizeSlider setIntegerValue:value];
	[mergedCheckbox setState:[defaults boolForKey:@"eyedrop merged"]];
}

- (int)sampleSize
{
	return [sizeSlider intValue];
}

- (BOOL)mergedSample
{
	return [mergedCheckbox state] == NSControlStateValueOn;
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[self sampleSize] forKey:@"eyedrop size"];
	[defaults setBool:[self mergedSample] forKey:@"eyedrop merged"];
}

@end
