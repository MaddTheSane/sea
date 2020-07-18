#include <tgmath.h>
#import "BrushOptions.h"
#import "ToolboxUtility.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaWarning.h"
#import "SeaDocument.h"
#import "SeaPrefs.h"
#import "SeaView.h"

enum {
	kQuadratic,
	kLinear,
	kSquareRoot
};

@implementation BrushOptions
@synthesize brushIsErasing = isErasing;

- (void)awakeFromNib
{
	NSInteger rate, style;
	BOOL fadeOn, pressureOn;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"brush fade"] == NULL) {
		[fadeCheckbox setState:NSOffState];
		[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), 10]];
		[fadeSlider setIntValue:10];
		[fadeSlider setEnabled:NO];
	}
	else {
		rate = [defaults integerForKey:@"brush fade rate"];
		if (rate < 1 || rate > 120)
			rate = 10;
		fadeOn = [defaults boolForKey:@"brush fade"];
		[fadeCheckbox setState:fadeOn];
		[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), rate]];
		[fadeSlider setIntegerValue:rate];
		[fadeSlider setEnabled:fadeOn];
	}
	
	if ([defaults objectForKey:@"brush pressure"] == NULL) {
		[pressureCheckbox setState:NSOffState];
		[pressurePopup selectItemAtIndex:kLinear];
		[pressurePopup setEnabled:NO];
	}
	else {
		style = [defaults integerForKey:@"brush pressure style"];
		if (style < kQuadratic || style > kSquareRoot)
			style = kLinear;
		pressureOn = [defaults boolForKey:@"brush pressure"];
		[pressureCheckbox setState:pressureOn];
		[pressurePopup selectItemAtIndex:style];
		[pressurePopup setEnabled:pressureOn];
	}
	
	if ([defaults objectForKey:@"brush scale"] == NULL) {
		[scaleCheckbox setState:NSOnState];
	}
	else {
		[scaleCheckbox setState:[defaults boolForKey:@"brush scale"]];
	}
	
	isErasing = NO;
	warnedUser = NO;
}

- (IBAction)update:(id)sender
{
	if (!warnedUser && [sender tag] == 3) {
		if ([pressureCheckbox state]) {
			if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_4 && NSAppKitVersionNumber < NSAppKitVersionNumber10_4_6) {
				[[SeaController seaWarning] addMessage:LOCALSTR(@"tablet bug message", @"There is a bug in Mac OS 10.4 that causes some tablets to incorrectly register their first touch at full strength. A workaround is provided in the \"Preferences\" dialog however the best solution is to upgrade to Mac OS 10.4.6 or later.") level:SeaWarningImportanceModerate];
				warnedUser = YES;
			}
		}
	}
	[fadeSlider setEnabled:[fadeCheckbox state]];
	[fadeCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"fade-out", @"Fade-out: %d"), [fadeSlider intValue]]];
	[pressurePopup setEnabled:[pressureCheckbox state]];
}

- (BOOL)fade
{
	return [fadeCheckbox state] == NSOnState;
}

- (int)fadeValue
{
	return [fadeSlider intValue];
}

- (BOOL)pressureSensitive
{
	return [pressureCheckbox state];
}

- (int)pressureValue:(NSEvent *)event
{
	double p;
	
	if ([pressureCheckbox state] == NSOffState)
		return 255;
	
	if (event == NULL)
		return 255;
			
	p = [event pressure];
	
	switch ([pressurePopup indexOfSelectedItem]) {
		case kLinear:
			return (int)(p * 255.0);
		break;
		case kQuadratic:
			return (int)((p * p) * 255.0);
		break;
		case kSquareRoot:
			return (int)(sqrt(p) * 255.0);
		break;
	}

	return 255;
}

- (BOOL)scale
{
	return [scaleCheckbox state] == NSOnState;
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (void)updateModifiers:(NSEventModifierFlags)modifiers
{
	[super updateModifiers:modifiers];
	AbstractModifiers modifier = [super modifier];
	
	switch (modifier) {
		case AbstractModifierAlt:
			isErasing = YES;
			break;
		default:
			isErasing = NO;
			break;
	}
}

- (IBAction)modifierPopupChanged:(id)sender
{
	switch ([[sender selectedItem] tag]) {
		case AbstractModifierAlt:
			isErasing = YES;
			break;
		default:
			isErasing = NO;
			break;
	}
	// We now need to update all of the documents because the modifiers, and thus possibly
	// the cursors and guides may have changed.
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	for (SeaDocument *doc in documents) {
		[doc docView].needsDisplay = YES;
	}
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[fadeCheckbox state] == NSControlStateValueOn forKey:@"brush fade"];
	[defaults setInteger:[fadeSlider integerValue] forKey:@"brush fade rate"];
	[defaults setBool:[pressureCheckbox state] == NSControlStateValueOn forKey:@"brush pressure"];
	[defaults setInteger:[pressurePopup indexOfSelectedItem] forKey:@"brush pressure style"];
	[defaults setInteger:[scaleCheckbox state] forKey:@"brush scale"];
}

@end
