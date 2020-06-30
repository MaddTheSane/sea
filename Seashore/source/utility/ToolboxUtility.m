#import "ToolboxUtility.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "OptionsUtility.h"
#import "ColorSelectView.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "UtilitiesManager.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "InfoUtility.h"
#import "AbstractOptions.h"
#import "SeaToolbarItem.h"
#import "ImageToolbarItem.h"
#import "StatusUtility.h"
#import "SeaWindowContent.h"
#import "WarningsUtility.h"
#import "SeashoreKit.h"

@interface ToolboxUtility () <NSFileManagerDelegate, NSToolbarDelegate>

@end

@interface NSObject (toolbarSelectors)
- (void)forward:(id)selector;
- (void)backward:(id)selector;
- (void)selectOpaque:(id)selector;
@end

static NSToolbarIdentifier const	DocToolbarIdentifier 	= @"Document Toolbar Instance Identifier";

static NSToolbarItemIdentifier const	SelectionIdentifier 	= @"Selection  Item Identifier";
static NSToolbarItemIdentifier const	DrawIdentifier 	= @"Draw Item Identifier";
static NSToolbarItemIdentifier const	EffectIdentifier = @"Effect Item Identifier";
static NSToolbarItemIdentifier const	TransformIdentifier = @"Transform Item Identifier";
static NSToolbarItemIdentifier const	ColorsIdentifier = @"Colors Item Identifier";

// Additional (Non-default) toolbar items
static NSToolbarItemIdentifier const	ZoomInToolbarItemIdentifier = @"Zoom In Toolbar Item Identifier";
static NSToolbarItemIdentifier const	ZoomOutToolbarItemIdentifier = @"Zoom Out Toolbar Item Identifier";
static NSToolbarItemIdentifier const	ActualSizeToolbarItemIdentifier = @"Actual Size Toolbar Item Identifier";
static NSToolbarItemIdentifier const	NewLayerToolbarItemIdentifier = @"New Layer Toolbar Item Identifier";
static NSToolbarItemIdentifier const	DuplicateLayerToolbarItemIdentifier = @"Duplicate Layer Toolbar Item Identifier";
static NSToolbarItemIdentifier const	ForwardToolbarItemIdentifier = @"Move Layer Forward  Toolbar Item Identifier";
static NSToolbarItemIdentifier const	BackwardToolbarItemIdentifier = @"Move Layer Backward Toolbar Item Identifier";
static NSToolbarItemIdentifier const	DeleteLayerToolbarItemIdentifier = @"Delete Layer Toolbar Item Identifier";
static NSToolbarItemIdentifier const	ToggleLayersToolbarItemIdentifier = @"Show/Hide Layers Item Identifier";
static NSToolbarItemIdentifier const	InspectorToolbarItemIdentifier = @"Show/Hide Inspector Toolbar Item Identifier";
static NSToolbarItemIdentifier const	FloatAnchorToolbarItemIdentifier = @"Float/Anchor Toolbar Item Identifier";
static NSToolbarItemIdentifier const	DuplicateSelectionToolbarItemIdentifier = @"Duplicate Selection Toolbar Item Identifier";
static NSToolbarItemIdentifier const	SelectNoneToolbarItemIdentifier = @"Select None Toolbar Item Identifier";
static NSToolbarItemIdentifier const	SelectAllToolbarItemIdentifier = @"Select All Toolbar Item Identifier";
static NSToolbarItemIdentifier const	SelectInverseToolbarItemIdentifier = @"Select Inverse Toolbar Item Identifier";
static NSToolbarItemIdentifier const	SelectAlphaToolbarItemIdentifier = @"Select Alpha Toolbar Item Identifier";

@implementation ToolboxUtility
@synthesize background;
@synthesize foreground;
@synthesize tool;
@synthesize colorView = colorSelectView;

- (instancetype)init
{
	if (self = [super init]) {
	foreground = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	background = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	delay_timer = NULL;
	tool = -1;
	oldTool = -1;
	selectionTools = @[@(SeaToolsSelectRect),
					  @(SeaToolsSelectEllipse),
					  @(SeaToolsLasso),
					  @(SeaToolsPolygonLasso),
					  @(SeaToolsWand)];
	drawTools =	@[@(SeaToolsPencil),
				 @(SeaToolsBrush),
				 @(SeaToolsText),
				 @(SeaToolsEraser),
				 @(SeaToolsBucket),
				 @(SeaToolsGradient)];
	effectTools =	@[@(SeaToolsEffect),
				 @(SeaToolsSmudge),
				 @(SeaToolsClone)];
	transformTools = @[@(SeaToolsEyedrop),
					 @(SeaToolsCrop),
					 @(SeaToolsZoom),
					 @(SeaToolsPosition)];
	
	}
	return self;
}

- (void)awakeFromNib
{

	// Create the toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: DocToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	
    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[document window] setToolbar: toolbar];
	
	[[SeaController utilitiesManager] setToolboxUtility: self forDocument:document];
}


- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	SeaToolbarItem *toolbarItem;
	
    if ([itemIdent isEqual: SelectionIdentifier]) {
        toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:SelectionIdentifier];
		[toolbarItem setView:selectionTBView];
		[toolbarItem setLabel:@"Selection Tools"];
		[toolbarItem setPaletteLabel:@"Selection Tools"];
		[toolbarItem setMenuFormRepresentation:selectionMenu];
		// set sizes
		[toolbarItem setMinSize: [selectionTBView frame].size];
		[toolbarItem setMaxSize: [selectionTBView frame].size];
	} else if([itemIdent isEqual:DrawIdentifier]) {
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:DrawIdentifier];
		[toolbarItem setView: drawTBView];
		[toolbarItem setLabel:@"Draw Tools"];
		[toolbarItem setPaletteLabel:@"Draw Tools"];
		[toolbarItem setMenuFormRepresentation:drawMenu];
		[toolbarItem setMinSize: [drawTBView frame].size];
		[toolbarItem setMaxSize: [drawTBView frame].size];
	} else if([itemIdent isEqual:EffectIdentifier]) {
		toolbarItem =[[SeaToolbarItem alloc] initWithItemIdentifier:EffectIdentifier];
		[toolbarItem setView:effectTBView];
		[toolbarItem setLabel:	@"Effect Tools"];
		[toolbarItem setPaletteLabel:@"Effect Tools"];
		[toolbarItem setMenuFormRepresentation:effectMenu];
		[toolbarItem setMinSize: [effectTBView frame].size];
		[toolbarItem setMaxSize: [effectTBView frame].size];
	} else if([itemIdent isEqual:TransformIdentifier]) {
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:TransformIdentifier];
		[toolbarItem setView:transformTBView];
		[toolbarItem setLabel:@"Transform Tools"];
		[toolbarItem setPaletteLabel:@"TransformTools"];
		[toolbarItem setMenuFormRepresentation:transformMenu];
		[toolbarItem setMinSize: [transformTBView frame].size];
		[toolbarItem setMaxSize: [transformTBView frame].size];
	} else if([itemIdent isEqual:ColorsIdentifier]) {
		toolbarItem = [[SeaToolbarItem alloc] initWithItemIdentifier:ColorsIdentifier];
		[toolbarItem setView:colorSelectView];
		[toolbarItem setLabel:@"Colors"];
		[toolbarItem setPaletteLabel:@"Colors"];
		[toolbarItem setMenuFormRepresentation:colorsMenu];
		[toolbarItem setMinSize: [colorSelectView frame].size];
		[toolbarItem setMaxSize: [colorSelectView frame].size];
	} else if ([itemIdent isEqual: NewLayerToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: NewLayerToolbarItemIdentifier label: LOCALSTR(@"new", @"New") imageNamed: @"toolbar/new" toolTip: LOCALSTR(@"new tooltip", @"Add a new layer to the image") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document] selector: @selector(addLayer:)];
	} else if ([itemIdent isEqual: DuplicateLayerToolbarItemIdentifier]) {
		return [[ImageToolbarItem alloc] initWithItemIdentifier: DuplicateLayerToolbarItemIdentifier label: LOCALSTR(@"duplicate", @"Duplicate") imageNamed: @"toolbar/duplicate" toolTip: LOCALSTR(@"duplicate tooltip", @"Duplicate the current layer") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document]  selector: @selector(duplicateLayer:)];
	} else if ([itemIdent isEqual: ForwardToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: ForwardToolbarItemIdentifier label: LOCALSTR(@"forward", @"Forward") imageNamed: @"toolbar/forward" toolTip: LOCALSTR(@"forward tooltip", @"Move the current layer forward") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document]  selector: @selector(forward:)];
	} else if ([itemIdent isEqual: BackwardToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: BackwardToolbarItemIdentifier label: LOCALSTR(@"backward", @"Backward") imageNamed: @"toolbar/backward" toolTip: LOCALSTR(@"backward tooltip", @"Move the current layer backward") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document]  selector: @selector(backward:)];
	} else if ([itemIdent isEqual: DeleteLayerToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: DeleteLayerToolbarItemIdentifier label: LOCALSTR(@"delete", @"Delete") image: [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)] toolTip: LOCALSTR(@"delete tooltip", @"Delete the current layer") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document]  selector: @selector(deleteLayer:)];
	} else if ([itemIdent isEqual: ZoomInToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: ZoomInToolbarItemIdentifier label: LOCALSTR(@"zoom in", @"Zoom In") imageNamed: @"toolbar/zoomIn" toolTip: LOCALSTR(@"zoom in tooltip", @"Zoom in on the current view") target: [document docView] selector: @selector(zoomIn:)];
	} else if ([itemIdent isEqual: ZoomOutToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: ZoomOutToolbarItemIdentifier label: LOCALSTR(@"zoom out", @"Zoom Out") imageNamed: @"toolbar/zoomOut" toolTip: LOCALSTR(@"zoom out tooltip", @"Zoom out from the current view") target: [document docView] selector: @selector(zoomOut:)];
	} else if ([itemIdent isEqual: ActualSizeToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: ActualSizeToolbarItemIdentifier label: LOCALSTR(@"actual size", @"Actual Size") imageNamed: @"toolbar/actualSize" toolTip: LOCALSTR(@"actual size tooltip", @"View the document at its actual size") target: [document docView] selector: @selector(zoomNormal:)];
	} else if ([itemIdent isEqual: ToggleLayersToolbarItemIdentifier]) {
		return [[ImageToolbarItem alloc] initWithItemIdentifier: ToggleLayersToolbarItemIdentifier label: LOCALSTR(@"toggle layers", @"Layers") imageNamed: @"toolbar/showhidelayers" toolTip: LOCALSTR(@"toggle layers tooltip", @"Show or hide the layers list view") target: [[SeaController utilitiesManager] pegasusUtilityForDocument:document] selector: @selector(toggleLayers:)];
	} else if ([itemIdent isEqual: InspectorToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: InspectorToolbarItemIdentifier label: LOCALSTR(@"information", @"Information") imageNamed: NSImageNameInfo toolTip: LOCALSTR(@"information tooltip", @"Show or hide point information") target: [[SeaController utilitiesManager] infoUtilityForDocument:document]  selector: @selector(toggle:)];
	} else if ([itemIdent isEqual: FloatAnchorToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: FloatAnchorToolbarItemIdentifier label: LOCALSTR(@"float", @"Float") imageNamed: @"toolbar/float-tb" toolTip: LOCALSTR(@"float tooltip", @"Float or anchor the current selection") target: [document contents] selector: @selector(toggleFloatingSelection:)];
	} else if ([itemIdent isEqual: DuplicateSelectionToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: DuplicateSelectionToolbarItemIdentifier label: LOCALSTR(@"duplicate", @"Duplicate") imageNamed: @"toolbar/duplicatesel" toolTip: LOCALSTR(@"duplicate tooltip", @"Duplicate the current selection") target: [document contents] selector: @selector(duplicate:)];
	} else if ([itemIdent isEqual: SelectNoneToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: SelectNoneToolbarItemIdentifier label: LOCALSTR(@"select none", @"None") imageNamed: @"toolbar/none" toolTip: LOCALSTR(@"select none tooltip", @"Select nothing") target: [document docView]  selector: @selector(selectNone:)];
	} else if ([itemIdent isEqual: SelectAllToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: SelectAllToolbarItemIdentifier label: LOCALSTR(@"select all", @"All") imageNamed: @"toolbar/selectall" toolTip: LOCALSTR(@"select All tooltip", @"Select all of the current layer") target: [document docView]  selector: @selector(selectAll:)];
	} else if ([itemIdent isEqual: SelectInverseToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: SelectInverseToolbarItemIdentifier label: LOCALSTR(@"select none", @"Inverse") imageNamed: @"toolbar/selectinverse" toolTip: LOCALSTR(@"select inverse tooltip", @"Select the inverse of the current selection") target: [document docView]  selector: @selector(selectInverse:)];
	} else if ([itemIdent isEqual: SelectAlphaToolbarItemIdentifier]) {
        return [[ImageToolbarItem alloc] initWithItemIdentifier: SelectAlphaToolbarItemIdentifier label: LOCALSTR(@"select alpha", @"Alpha") imageNamed: @"toolbar/selectalpha" toolTip: LOCALSTR(@"select alpha tooltip", @"Select a copy of the alpha transparency channel") target: [document docView]  selector: @selector(selectOpaque:)];
    }
	
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return @[NSToolbarFlexibleSpaceItemIdentifier,
			SelectionIdentifier,
			DrawIdentifier,
			EffectIdentifier,
			TransformIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			ColorsIdentifier];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return @[SelectionIdentifier,
			DrawIdentifier,
			EffectIdentifier,
			TransformIdentifier,
			ColorsIdentifier,
			//NewLayerToolbarItemIdentifier,
			//DuplicateLayerToolbarItemIdentifier,
			//ForwardToolbarItemIdentifier,
			//BackwardToolbarItemIdentifier,
			//DeleteLayerToolbarItemIdentifier,
			//ToggleLayersToolbarItemIdentifier,
			ZoomInToolbarItemIdentifier,
			ZoomOutToolbarItemIdentifier,
			ActualSizeToolbarItemIdentifier,
			//InspectorToolbarItemIdentifier,
			FloatAnchorToolbarItemIdentifier,
			DuplicateSelectionToolbarItemIdentifier,
			SelectNoneToolbarItemIdentifier,		
			SelectAllToolbarItemIdentifier,		
			SelectInverseToolbarItemIdentifier,		
			SelectAlphaToolbarItemIdentifier,		
			NSToolbarCustomizeToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarSeparatorItemIdentifier];
}

- (void)setForeground:(NSColor *)color
{
	foreground = color;
	if (delay_timer) {
		[delay_timer invalidate];
	}
	delay_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[[document tools] getTool:SeaToolsText]  selector:@selector(preview:) userInfo:NULL repeats:NO];
	[[[SeaController utilitiesManager] statusUtilityFor:document] updateQuickColor];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)activate
{
	if (tool == -1)
		[self changeToolTo:SeaToolsSelectRect];
	// Set the document appropriately
	[colorSelectView setDocument:document];
		
	// Then pretend a tool change
	[self update:YES];
}

- (void)deactivate
{
	[colorSelectView setDocument:document];
	for (SeaToolsDefines i = SeaToolsFirstSelection; i <= SeaToolsLastSelection; i++) {
		[[toolbox cellWithTag:i] setEnabled:YES];
	}
}

- (void)update:(BOOL)full
{
	if (full) {
		/* Disable or enable the tool */
		if (document.selection.floating) {
			for (SeaToolsDefines i = SeaToolsFirstSelection; i <= SeaToolsLastSelection; i++) {
				[selectionTBView setEnabled:NO forSegment:i];
			}
			[selectionMenu setEnabled:NO];
		} else {
			for (SeaToolsDefines i = SeaToolsFirstSelection; i <= SeaToolsLastSelection; i++) {
				[selectionTBView setEnabled:YES forSegment:i];
			}
			[selectionMenu setEnabled:YES];
		}
		// Implement the change
		[[document docView] setNeedsDisplay:YES];
		[optionsUtility update];
		[[SeaController seaHelp] updateInstantHelp:tool];
	}
	[colorSelectView update];
}

- (IBAction)selectToolUsingTag:(id)sender
{
	[self changeToolTo:[sender tag] % 100];
}

- (IBAction)selectToolFromSender:(NSSegmentedControl*)sender
{
	[self changeToolTo:[[sender cell] tagForSegment:sender.selectedSegment] % 100];
}

- (void)changeToolTo:(SeaToolsDefines)newTool
{
	BOOL updateCrop = NO;
	
	[[document helpers] endLineDrawing];
	if (tool == SeaToolsCrop || newTool == SeaToolsCrop) {
		updateCrop = YES;
		[[document docView] setNeedsDisplay:YES];
	}
	if (tool == newTool && [[NSApp currentEvent] type] == NSLeftMouseUp && [[NSApp currentEvent] clickCount] > 1) {
		[[[SeaController utilitiesManager] optionsUtilityForDocument:document] show:NULL];
	} else {
		tool = newTool;
		// Deselect the old tool
		int i;
		for(i = 0; i < [selectionTools count]; i++)
			[selectionTBView setSelected:NO forSegment:i];
		for(i = 0; i < [drawTools count]; i++)
			[drawTBView setSelected:NO forSegment:i];
		for(i = 0; i < [effectTools count]; i++)
			[effectTBView setSelected:NO forSegment:i];
		for(i = 0; i < [transformTools count]; i++)
			[transformTBView setSelected:NO forSegment:i];
		
		[selectionTBView selectSegmentWithTag:tool];
		[drawTBView selectSegmentWithTag:tool];
		[effectTBView selectSegmentWithTag:tool];
		[transformTBView selectSegmentWithTag:tool];

		[self update:YES];
	}
	if (updateCrop)
		[[[SeaController utilitiesManager] infoUtilityForDocument:document] update];
}

- (void)floatTool
{
	// Show the banner
	[[document warnings] showFloatBanner];
	
	oldTool = tool;
	[self changeToolTo: SeaToolsPosition];
}

- (void)anchorTool
{
	// Hide the banner
	[[document warnings] hideFloatBanner];
	if (oldTool != -1)
		[self changeToolTo: oldTool];
}

- (void)setEffectEnabled:(BOOL)enable
{
	[effectTBView setEnabled:enable forSegment:SeaToolsEffect];
	//[[effectTBView cellAtRow: 0 column: kEffectTool] setEnabled: enable];
}

- (BOOL)validateMenuItem:(id)menuItem
{	
	if ([menuItem tag] >= 600 && [menuItem tag] < 700) {
		[menuItem setState:([menuItem tag] == tool + 600)];
	}
	
	return YES;
}


@end
