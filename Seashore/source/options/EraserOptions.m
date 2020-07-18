#import "EraserOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaHelp.h"
#import "SeaTools.h"

@implementation EraserOptions

- (void)awakeFromNib
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"eraser opacity"] == NULL) {
		value = 100;
	}
	else {
		value = [defaults integerForKey:@"eraser opacity"];
		if (value < [opacitySlider minValue] || value > [opacitySlider maxValue])
			value = 100;
	}
	[opacitySlider setIntegerValue:value];
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), value]];
	[mimicBrushCheckbox setState:[defaults boolForKey:@"eraser mimicBrush"]];
}

- (IBAction)opacityChanged:(id)sender
{		
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
}

- (int)opacity
{
	return [opacitySlider intValue] * 2.55;
}

- (BOOL)mimicBrush
{
	return [mimicBrushCheckbox state] == NSControlStateValueOn;
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[opacitySlider intValue] forKey:@"eraser opacity"];
	[defaults setBool:[mimicBrushCheckbox state] ? YES : NO forKey:@"eraser mimicBrush"];
}

@end
