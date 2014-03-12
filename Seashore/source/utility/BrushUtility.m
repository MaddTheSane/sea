#import "BrushUtility.h"
#import "BrushView.h"
#import "SeaBrush.h"
#import "UtilitiesManager.h"
#import "SeaController.h"
#import "InfoPanel.h"

#ifdef TODO
#warning Make brushes lazy, that is if they are not in the active group they are not memory
#endif

@implementation BrushUtility

- (id)init
{		
	// Load the brushes
	[self loadBrushes:NO];
	
	// Determine the currently active brush group
	if ([gUserDefaults objectForKey:@"active brush group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active brush group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active brush 	
	if ([gUserDefaults objectForKey:@"active brush"] == NULL)
		activeBrushIndex = 12;
	else
		activeBrushIndex = [gUserDefaults integerForKey:@"active brush"];
	if (activeBrushIndex < 0 || activeBrushIndex >= [groups[activeGroupIndex] count])
		activeBrushIndex = 0;
	
	return self;
}

- (void)awakeFromNib
{
	int yoff, i;

	[super awakeFromNib];
	
	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setBorderType:NSGrooveBorder];
	[view setDocumentView:[[BrushView alloc] initWithMaster:self]];
	[view setBackgroundColor:[NSColor lightGrayColor]];
	if ([[view documentView] bounds].size.height > 3 * kBrushPreviewSize) {
		yoff = MIN((activeBrushIndex / kBrushesPerRow) * kBrushPreviewSize, ([[self brushes] count] / kBrushesPerRow - 2) * kBrushPreviewSize);
		[[view contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[view reflectScrolledClipView:[view contentView]];
	[view setLineScroll:kBrushPreviewSize];
	
	// Configure the pop-up menu
	[brushGroupPopUp removeAllItems];
	[brushGroupPopUp addItemWithTitle:groupNames[0]];
	[[brushGroupPopUp itemAtIndex:0] setTag:0];
	if (customGroups != 0) {
		[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
		for (i = 1; i < customGroups + 1; i++) {
			[brushGroupPopUp addItemWithTitle:groupNames[i]];
			[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
		}
	}
	[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = customGroups + 1; i < [groupNames count]; i++) {
		[brushGroupPopUp addItemWithTitle:groupNames[i]];
		[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the brush that it is active
	[self setActiveBrushIndex:activeBrushIndex];
	
	// Set the window's properties
	[(InfoPanel *)window setPanelStyle:kVerticalPanelStyle];
	
	[[SeaController utilitiesManager] setBrushUtility: self for:document];
}

- (void)shutdown
{
	[gUserDefaults setInteger:activeBrushIndex forKey:@"active brush"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active brush group"];
}

- (void)activate:(id)sender
{
	document = sender;
}

- (void)deactivate
{
	document = NULL;
}

- (void)update
{
	activeGroupIndex = [[brushGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	if (activeBrushIndex >= [groups[activeGroupIndex] count])
		activeBrushIndex = 0;
	[self setActiveBrushIndex:activeBrushIndex];
	[[view documentView] update];
	[view setNeedsDisplay:YES];
}

// Apologies for the bad code in the next method

- (void)loadBrushes:(BOOL)update
{
	NSArray *files;
	NSString *tempPathA, *tempPathB;
	NSArray *newValues, *newKeys, *tempBrushArray, *tempArray;
	BOOL isDirectory;
	id tempBrush;
	int i, j;
	
	// Create a dictionary of all brushes
	brushes = @{};
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"] stringByAppendingString:files[i]];
		if ([[tempPathA pathExtension] isEqualToString:@"gbr"]) {
			tempBrush = [[SeaBrush alloc] initWithContentsOfFile:tempPathA];
			if (tempBrush) {
				newKeys = [[brushes allKeys] arrayByAddingObject:tempPathA];
				newValues = [[brushes allValues] arrayByAddingObject:tempBrush];
				brushes = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
			}
		}
	}
	
	// Create the all group
	tempBrushArray = [[brushes allValues] sortedArrayUsingSelector:@selector(compare:)];
	groups = @[tempBrushArray];
	groupNames = @[LOCALSTR(@"all group", @"All")];
	
	// Create the custom groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"];
		tempPathB = [tempPathA stringByAppendingString:files[i]];
		if ([[tempPathB pathExtension] isEqualToString:@"txt"]) {
			tempArray = [NSArray arrayWithContentsOfFile:tempPathB];
			if (tempArray) {
				tempBrushArray = @[];
				for (j = 0; j < [tempArray count]; j++) {
					tempBrush = brushes[[tempPathA stringByAppendingString:tempArray[j]]];
					if (tempBrush) {
						tempBrushArray = [tempBrushArray arrayByAddingObject:tempBrush];
					}
				}
				if ([tempBrushArray count] > 0) {
					groups = [groups arrayByAddingObject:tempBrushArray];
					groupNames = [groupNames arrayByAddingObject:[[tempPathB lastPathComponent] stringByDeletingPathExtension]];
				}
			}	
		}
	}
	customGroups = [groups count] - 1;
	
	// Create the other groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/brushes"]];
	for (i = 0; i < [files count]; i++) {
		tempPathA = [[[gMainBundle resourcePath] stringByAppendingString:@"/brushes/"] stringByAppendingString:files[i]];
		[gFileManager fileExistsAtPath:tempPathA isDirectory:&isDirectory];
		if (isDirectory) {
			tempPathA = [tempPathA stringByAppendingString:@"/"];
			tempArray = [gFileManager subpathsAtPath:tempPathA];
			tempBrushArray = @[];
			for (j = 0; j < [tempArray count]; j++) {
				tempBrush = brushes[[tempPathA stringByAppendingString:tempArray[j]]];
				if (tempBrush) {
					tempBrushArray = [tempBrushArray arrayByAddingObject:tempBrush];
				}
			}
			if ([tempBrushArray count] > 0) {
				tempBrushArray = [tempBrushArray sortedArrayUsingSelector:@selector(compare:)];
				groups = [groups arrayByAddingObject:tempBrushArray];
				groupNames = [groupNames arrayByAddingObject:[tempPathA lastPathComponent]];
			}
		}
	}
	
	// Retain the groups and groupNames
	
	// Update utility if requested
	if (update)
		[self update];
}

- (IBAction)changeSpacing:(id)sender
{
	[spacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (int)spacing
{
	return ([spacingSlider intValue] / 5 * 5 == 0) ? 1 : [spacingSlider intValue] / 5 * 5;
}

- (id)activeBrush
{
	return groups[activeGroupIndex][activeBrushIndex];
}

- (int)activeBrushIndex
{
	return activeBrushIndex;
}

- (void)setActiveBrushIndex:(int)index
{
	id oldBrush = groups[activeGroupIndex][activeBrushIndex];
	id newBrush = groups[activeGroupIndex][index];
	
	[oldBrush deactivate];
	activeBrushIndex = index;
	[brushNameLabel setStringValue:[newBrush name]];
	[spacingSlider setIntValue:[(SeaBrush*)newBrush spacing]];
	[spacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
	[newBrush activate];
}

- (NSArray *)brushes
{
	return groups[activeGroupIndex];
}


@end
