#import "PencilOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"

@implementation PencilOptions

- (void)awakeFromNib
{
	NSInteger value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:@"pencil size"] == NULL) {
		value = 1;
	}
	else {
		value = [defaults integerForKey:@"pencil size"];
		if (value < [sizeSlider minValue] || value > [sizeSlider maxValue])
			value = 1;
	}
	[sizeSlider setIntValue:value];
	isErasing = NO;
}

- (int)pencilSize
{
	return [sizeSlider intValue];
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (BOOL)pencilIsErasing
{
	return isErasing;
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	
	switch (modifier) {
		case kAltModifier:
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
		case kAltModifier:
			isErasing = YES;
			break;
		default:
			isErasing = NO;
			break;
	}
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	for (i = 0; i < [documents count]; i++) {
		[[(SeaDocument *)documents[i] docView] setNeedsDisplay:YES];
	}
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[sizeSlider intValue] forKey:@"pencil size"];
}

@end
