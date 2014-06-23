#import "PencilOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocument.h"
#import "SeaPrefs.h"
#import "SeaView.h"

@interface PencilOptions ()
@property (readwrite) BOOL pencilIsErasing;
@end

@implementation PencilOptions
@synthesize pencilIsErasing = isErasing;

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
	[sizeSlider setIntegerValue:value];
	self.pencilIsErasing = NO;
}

- (int)pencilSize
{
	return [sizeSlider intValue];
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (void)updateModifiers:(AbstractModifiers)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	
	switch (modifier) {
		case kAltModifier:
			self.pencilIsErasing = YES;
			break;
		default:
			self.pencilIsErasing = NO;
			break;
	}
}

- (IBAction)modifierPopupChanged:(id)sender
{
	switch ([[sender selectedItem] tag]) {
		case kAltModifier:
			self.pencilIsErasing = YES;
			break;
		default:
			self.pencilIsErasing = NO;
			break;
	}
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];

	for (SeaDocument *doc in documents) {
		[doc docView].needsDisplay = YES;
	}
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[sizeSlider integerValue] forKey:@"pencil size"];
}

@end
