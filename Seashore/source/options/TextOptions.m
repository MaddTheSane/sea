#import "TextOptions.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "TextTool.h"
#import "SeaDocument.h"

id gNewFont;

@interface NSObject (changeFont)
- (IBAction)changeSpecialFont:(id)sender;
@end

@implementation TextOptions

- (void)awakeFromNib
{	
	int ivalue;
	BOOL bvalue;
	NSFont *font;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Handle the text alignment
	if ([defaults objectForKey:@"text alignment"] == NULL) {
		ivalue = NSLeftTextAlignment;
	}
	else {
		ivalue = (int)[defaults integerForKey:@"text alignment"];
		if (ivalue < 0 || ivalue >= [alignmentControl segmentCount])
			ivalue = NSLeftTextAlignment;
	}
	[alignmentControl setSelectedSegment:ivalue];
	
	// Handle the text outline slider
	if ([defaults objectForKey:@"text outline slider"] == NULL) {
		ivalue = 5;
	}
	else {
		ivalue = (int)[defaults integerForKey:@"text outline slider"];
		if (ivalue < 1 || ivalue > 24)
			ivalue = 5;
	}
	[outlineSlider setIntValue:ivalue];
	
	// Handle the text outline checkbox
	if ([defaults objectForKey:@"text outline checkbox"] == NULL) {
		bvalue = NO;
	}
	else {
		bvalue = [defaults boolForKey:@"text outline checkbox"];
	}
	[outlineCheckbox setState:bvalue];
	
	// Enable or disable the slider appropriately
	if ([outlineCheckbox state])
		[outlineSlider setEnabled:YES];
	else
		[outlineSlider setEnabled:NO];
	
	// Show the slider value
	[outlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [outlineSlider intValue]]];
	
	// Handle the text fringe checkbox
	if ([defaults objectForKey:@"text fringe checkbox"] == NULL) {
		bvalue = YES;
	}
	else {
		bvalue = [defaults boolForKey:@"text fringe checkbox"];
	}
	[fringeCheckbox setState:bvalue];
	
	// Set up font manager
	gNewFont = NULL;
	fontManager = [NSFontManager sharedFontManager];
	[fontManager setAction:@selector(changeSpecialFont:)];
	if ([defaults objectForKey:@"text font"] == NULL) {
		font = [NSFont userFontOfSize:0];
		[fontManager setSelectedFont:font isMultiple:NO];
		[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
	}
	else {
		font = [NSFont fontWithName:[defaults objectForKey:@"text font"] size:[defaults integerForKey:@"text size"]];
		[fontManager setSelectedFont:font isMultiple:NO];
		[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
	}
}

- (IBAction)showFonts:(id)sender
{
	[fontManager orderFrontFontPanel:self];
}

- (IBAction)changeFont:(id)sender
{
	gNewFont = [sender convertFont:[sender selectedFont]];
	[fontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [gNewFont displayName],  (int)[gNewFont pointSize]]];
	[(TextTool *)[[document tools] getTool:kTextTool] preview:NULL];
	gNewFont = NULL;
}

- (NSTextAlignment)alignment
{
	switch ([alignmentControl selectedSegment]) {
		case 0:
			return NSLeftTextAlignment;
		break;
		case 1:
			return NSCenterTextAlignment;
		break;
		case 2:
			return NSRightTextAlignment;
		break;
	}
	
	return NSLeftTextAlignment;
}

- (int)outline
{
	if ([outlineCheckbox state]) {
		return [outlineSlider intValue];
	}
	
	return 0;
}

- (BOOL)useSubpixel
{
	return YES;
}

- (BOOL)useTextures
{
	return [[SeaController seaPrefs] useTextures];
}

- (BOOL)allowFringe
{
	return [fringeCheckbox state];
}

- (IBAction)update:(id)sender
{
	// Enable or disable the slider appropriately
	if ([outlineCheckbox state])
		[outlineSlider setEnabled:YES];
	else
		[outlineSlider setEnabled:NO];
	
	// Show the slider value
	[outlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [outlineSlider intValue]]];
		
	// Update the text tool
	[(TextTool *)[[document tools] getTool:kTextTool] preview:NULL];
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[alignmentControl selectedSegment] forKey:@"text alignment"];
	[defaults setObject:[outlineCheckbox state] ? @"YES" : @"NO" forKey:@"text outline checkbox"];
	[defaults setInteger:[outlineSlider intValue] forKey:@"text outline slider"];
	[defaults setObject:[fringeCheckbox state] ? @"YES" : @"NO" forKey:@"text fringe checkbox"];
	[defaults setObject:[[fontManager selectedFont] fontName] forKey:@"text font"];
	[defaults setInteger:(int)[[fontManager selectedFont] pointSize] forKey:@"text size"];
}

@end
