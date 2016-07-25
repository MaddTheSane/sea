#import "LayerSettings.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "PegasusUtility.h"
#import "SeaDocument.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "InfoPanel.h"

@implementation LayerSettings

- (void)awakeFromNib
{
	settingsLayer = nil;
	[panel setPanelStyle:kHorizontalPanelStyle];	
}

- (void)activate
{
}

- (void)deactivate
{
}

- (void)showSettings:(SeaLayer *)layer from:(NSPoint)point
{
	id contents = [document contents];
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	units = [document measureStyle];
	
	// Set the layer title correctly
	if ([layer name]) {
		[layerTitle setStringValue:[layer name]];
		[layerTitle setEnabled:YES];
	}
	else {
		[layerTitle setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
		[layerTitle setEnabled:NO];
	}
	
	[leftValue setStringValue:SeaStringFromPixels([layer xoff],units,xres)];
	[topValue setStringValue:SeaStringFromPixels([layer yoff], units, yres)];
	[widthValue setStringValue:SeaStringFromPixels([layer width],units,xres)];
	[heightValue setStringValue:SeaStringFromPixels([layer height],units, yres)];	
	[leftUnits setTitle:SeaUnitsString(units)];
	[topUnits setTitle:SeaUnitsString(units)];	
	[widthUnits setTitle:SeaUnitsString(units)];
	[heightUnits setTitle:SeaUnitsString(units)];
	
	[channelEditingMatrix selectCellAtRow:[[document contents] selectedChannel] column:0];

	if([layer hasAlpha]){
		[[channelEditingMatrix cellAtRow:1 column:0] setEnabled:YES];
		[[channelEditingMatrix cellAtRow:2 column:0] setEnabled:YES];
	} else {
		[[channelEditingMatrix cellAtRow:1 column:0] setEnabled:NO];
		[[channelEditingMatrix cellAtRow:2 column:0] setEnabled:NO];
	}

	
	if (document && layer) {
		
		// Set the opacity correctly
		if ([layer floating]) {
			[opacitySlider setIntValue:[layer opacity]];
			[opacitySlider setEnabled:NO];
			[opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[layer opacity] / 2.55]];
		}
		else {
			[opacitySlider setIntValue:[layer opacity]];
			[opacitySlider setEnabled:YES];
			[opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[layer opacity] / 2.55]];
		}
		
		// Set the mode correctly
		if ([layer floating]) {
			[modePopup selectItemAtIndex:[modePopup indexOfItemWithTag:[layer mode]]];
			[modePopup setEnabled:NO];
		}
		else {
			[modePopup selectItemAtIndex:[modePopup indexOfItemWithTag:[layer mode]]];
			[modePopup setEnabled:YES];
		}
		
		[linkedCheckbox setEnabled: YES];
		[linkedCheckbox setState:[layer linked]];

		[alphaEnabledCheckbox setEnabled: [layer canToggleAlpha]];
		[alphaEnabledCheckbox setState:[layer hasAlpha]];
	}else{
		// Turn off the opacity
		[opacitySlider setIntValue:255];
		[opacitySlider setEnabled:NO];
		[opacityLabel setStringValue:@"100.0%"];
		
		// Turn off the mode
		[modePopup selectItemAtIndex:0];
		[modePopup setEnabled:NO];
		
		[linkedCheckbox setEnabled:NO];
		[alphaEnabledCheckbox setEnabled:NO];
	}
	
	// Display layer settings panel
	[panel orderFrontToGoal:point onWindow: [document window]];
	
	settingsLayer = layer;
	[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	id contents = [document contents];
	SeaLayer* layer = settingsLayer;
	int newLeftValue, newTopValue;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];

	// Parse width and height	
	newLeftValue = SeaPixelsFromFloat([leftValue floatValue],units, xres);
	newTopValue = SeaPixelsFromFloat([topValue floatValue],units,yres);
	
	if ([layer xoff] != newLeftValue || [layer yoff] != newTopValue)
		[self setOffsetsLeft:newLeftValue top:newTopValue index:[layer index]];
	
	// Change the layer's name
	if ([layer name]) {
		if (![[layerTitle stringValue] isEqualToString:[layer name]])
			[self setName:[NSString stringWithString:[layerTitle stringValue]] index:[layer index]];
	}
	
	// End the panel
	[NSApp stopModal];
	[[document window] removeChildWindow:panel];
	[panel orderOut:self];

	settingsLayer = nil;
}

- (IBAction)cancel:(id)sender
{
	settingsLayer = nil;
	[NSApp stopModal];
	[[document window] removeChildWindow:panel];
	[panel orderOut:self];
}

- (void)setOffsetsLeft:(int)left top:(int)top index:(NSInteger)index
{
	SeaLayer* layer;
	IntPoint oldOffsets;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
	layer = [[document contents] layer:index];
	
	// Allow the undo/redo
	oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
	[[[document undoManager] prepareWithInvocationTarget:self] setOffsetsLeft:oldOffsets.x top:oldOffsets.y index:index];
	
	// Change the offsets
	[layer setOffsets:IntMakePoint(left, top)];
	
	// Update as required
	[[document helpers] layerOffsetsChanged:index from:oldOffsets];
}

- (void)setName:(NSString *)newName index:(NSInteger)index
{
	SeaLayer* layer;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
	layer = [[document contents] layer:index];
	
	// Allow the undo/redo
	[[[document undoManager] prepareWithInvocationTarget:self] setName:[layer name] index:index];
	
	// Change the name
	[layer setName:newName];
	
	// Update the view
	[[document helpers] layerTitleChanged];
}

- (IBAction)changeMode:(id)sender
{
	SeaLayer* layer = settingsLayer;
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoMode:[layer index] to:[layer mode]];
	[layer setMode:(int)[[modePopup selectedItem] tag]];
	[[document helpers] layerAttributesChanged:kActiveLayer hold:YES];
}

- (void)undoMode:(NSInteger)index to:(int)value
{
	SeaLayer* layer = [[document contents] layer:index];
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoMode:index to:[layer mode]];
	[layer setMode:value];
	[[document contents] setActiveLayerIndex:index];
	[[document helpers] layerAttributesChanged:index hold:NO];
}

- (IBAction)changeOpacity:(id)sender
{
	SeaLayer* layer = settingsLayer;
	
	if ([[NSApp currentEvent] type] == NSLeftMouseDown)
		[[[document undoManager] prepareWithInvocationTarget:self] undoOpacity:[layer index] to:[layer opacity]];
	if ([layer width] * [layer height] < kMaxPixelsForLiveUpdate || [[NSApp currentEvent] type] == NSLeftMouseUp) {
		[layer setOpacity:[opacitySlider intValue]];
		[[document helpers] layerAttributesChanged:kActiveLayer hold:YES];
	}
	[opacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[opacitySlider intValue] / 2.55]];
}

- (void)undoOpacity:(NSInteger)index to:(int)value
{
	SeaLayer* layer = [[document contents] layer:index];
	
	[[[document undoManager] prepareWithInvocationTarget:self] undoOpacity:index to:[layer opacity]];
	[layer setOpacity:value];
	[[document contents] setActiveLayerIndex:index];
	[[document helpers] layerAttributesChanged:index hold:NO];
}


- (IBAction)changeLinked:(id)sender
{
	[[document contents] setLinked:[linkedCheckbox state] forLayer: [settingsLayer index]];
	[linkedCheckbox setState:[settingsLayer linked]];
}

- (IBAction)changeEnabledAlpha:(id)sender
{
	SeaLayer* layer = settingsLayer;

	if([layer canToggleAlpha]){
		[layer toggleAlpha];
	}
	[alphaEnabledCheckbox setState: [layer hasAlpha]];
}

- (IBAction)changeChannelEditing:(id)sender
{
	[[document contents] setSelectedChannel:(int)[channelEditingMatrix selectedRow]];
	[[document helpers] channelChanged];
}


@end
