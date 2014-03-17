#import "SmudgeOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation SmudgeOptions

- (void)awakeFromNib
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"smudge rate"] == NULL) {
		value = 50;
	}
	else {
		value = [defaults integerForKey:@"smudge rate"];
		if (value < 0 || value > 100)
			value = 50;
	}
	[rateSlider setIntValue:value];
	[rateLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"rate", @"Rate: %d%%"), value]];
	//[mergedCheckbox setState:[defaults boolForKey:@"smudge merged"]];
}

/*
- (BOOL)mergedSample
{
	return [mergedCheckbox state];
}
*/

- (IBAction)rateChanged:(id)sender
{		
	[rateLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"rate", @"Rate: %d%%"), [rateSlider intValue]]];
}

- (int)rate
{
	return [rateSlider intValue] * 2.55;
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[rateSlider integerValue] forKey:@"smudge rate"];
	//[defaults setInteger:[self mergedSample] forKey:@"smudge merged"];
}

@end
