#import "BucketOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation BucketOptions

- (void)awakeFromNib
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"bucket tolerance"] == NULL) {
		[toleranceSlider setIntValue:15];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), 15]];
	}
	else {
		value = [defaults integerForKey:@"bucket tolerance"];
		if (value < 0 || value > 255)
			value = 0;
		[toleranceSlider setIntegerValue:value];
		[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), value]];
	}
	
	if([defaults objectForKey:@"bucket intervals"] == NULL){
		[intervalsSlider setIntValue:15];
	}else{
		value = [defaults integerForKey:@"bucket intervals"];
		[intervalsSlider setIntegerValue:value];
	}
	
}

- (IBAction)toleranceSliderChanged:(id)sender
{
	[toleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), [toleranceSlider intValue]]];
}

- (int)tolerance
{
	return [toleranceSlider intValue];
}

- (int)numIntervals
{
	return [intervalsSlider intValue];
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[toleranceSlider intValue] forKey:@"bucket tolerance"];
	[defaults setInteger:[intervalsSlider intValue] forKey:@"bucket intervals"];
}

@end
