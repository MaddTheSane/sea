#import "InfoUtility.h"
#import "SeaDocument.h"
#import "ToolboxUtility.h"
#import "SeaTools.h"
#import "EyedropTool.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "SeaContent.h"
#import "SeaPrefs.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaPrefs.h"
#import "PositionTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "CropTool.h"
#import "Units.h"
#import "LayerControlView.h"
#import "SeaWindowContent.h"

@implementation InfoUtility

- (void)awakeFromNib
{
	// Shown By Default
	[[SeaController utilitiesManager] setInfoUtility: self forDocument:document];
	[(LayerControlView *)controlView setHasResizeThumb:YES];
	
	if(![self visible]){
		[toggleButton setImage:[NSImage imageNamed:@"show-infoTemplate"]];
	}
}

- (void)shutdown
{	
}

- (void)activate
{
	if([self visible]){
		[self update];
	}
}

- (void)deactivate
{
	
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: SeaWindowRegionPointInformation];
	[toggleButton setImage:[NSImage imageNamed:@"hide-infoTemplate"]];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: SeaWindowRegionPointInformation];	
	[toggleButton setImage:[NSImage imageNamed:@"show-infoTemplate"]];
}

- (IBAction)toggle:(id)sender
{
	if ([self visible]) {
		[self hide:sender];
	}
	else {
		[self show:sender];
	}
}

- (void)update
{
	IntPoint point, delta;
	IntSize size;
	NSColor *color;
	int xres, yres;
	SeaToolsDefines curToolIndex = [[[SeaController utilitiesManager] toolboxUtilityForDocument:document] tool];
	
	// Show no values
	if (!document) {
		[xValue setStringValue:@""];
		[yValue setStringValue:@""];
		[widthValue setStringValue:@""];
		[heightValue setStringValue:@""];
		[deltaX setStringValue:@""];
		[deltaY setStringValue:@""];
		[redValue setStringValue:@""];
		[greenValue setStringValue:@""];
		[blueValue setStringValue:@""];
		[alphaValue setStringValue:@""];
		[radiusValue setStringValue:@""];
		[colorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
		return;
	}
	
	// Set the radius value
	[radiusValue setIntValue:[[[document tools] getTool:SeaToolsEyedrop] sampleSize]];

	// Update the document information
	xres = [[document contents] xres];
	yres = [[document contents] yres];

	// Get the selection
	if (curToolIndex == SeaToolsCrop) {
		size = [[[document tools] currentTool] cropRect].size;
	} else if (document.selection.active) {
		size = [[document selection] globalRect].size;
	} else {
		size.height = size.width = 0;
	}

	point = [[document docView] getMousePosition:YES];
	delta = [[document docView] delta];
	SeaUnits units = [document measureStyle];

	NSString *label = SeaUnitsString(units);
	[widthValue setStringValue:[SeaStringFromPixels(size.width, units, xres) stringByAppendingFormat:@" %@", label]];
	[heightValue setStringValue:[SeaStringFromPixels(size.height, units, yres) stringByAppendingFormat:@" %@", label]];
	[deltaX setStringValue:[SeaStringFromPixels(delta.x, units, xres) stringByAppendingFormat:@" %@", label]];
	[deltaY setStringValue:[SeaStringFromPixels(delta.y, units, yres) stringByAppendingFormat:@" %@", label]];
	[xValue setStringValue:[SeaStringFromPixels(point.x, units, xres) stringByAppendingFormat:@" %@", label]];
	[yValue setStringValue:[SeaStringFromPixels(point.y, units, yres) stringByAppendingFormat:@" %@", label]];

	// Update the RGBA values
	color = [[[document tools] getTool:SeaToolsEyedrop] getColor];
	if (color) {
		[colorWell setColor:color];
		if ([[color colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) {
			[redValue setIntValue:[color redComponent] * 255.0];
			[greenValue setIntValue:[color greenComponent] * 255.0];
			[blueValue setIntValue:[color blueComponent] * 255.0];
			[alphaValue setIntValue:[color alphaComponent] * 255.0];
		}
		else if ([[color colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace]) {
			[redValue setIntValue:[color whiteComponent] * 255.0];
			[greenValue setIntValue:[color whiteComponent] * 255.0];
			[blueValue setIntValue:[color whiteComponent] * 255.0];
			[alphaValue setIntValue:[color alphaComponent] * 255.0];
		}
		else {
			NSLog(@"Color space not recognized by information utility.");
		}
	}
	
	if(point.x == -1){
		[xValue setStringValue:@""];
		[yValue setStringValue:@""];
		[redValue setStringValue:@""];
		[greenValue setStringValue:@""];
		[blueValue setStringValue:@""];
		[alphaValue setStringValue:@""];
		
		[colorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
	}
}

- (BOOL)visible
{
	return [[[document window] contentView] visibilityForRegion: SeaWindowRegionPointInformation];
}

@end
