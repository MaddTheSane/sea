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
@synthesize activeBrushIndex;

- (instancetype)init
{		
	if (self = [super init]) {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Load the brushes
	[self loadBrushes:NO];
	
	// Determine the currently active brush group
	if ([defaults objectForKey:@"active brush group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [defaults integerForKey:@"active brush group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active brush 	
	if ([defaults objectForKey:@"active brush"] == NULL)
		activeBrushIndex = 12;
	else
		activeBrushIndex = [defaults integerForKey:@"active brush"];
	if (activeBrushIndex < 0 || activeBrushIndex >= [groups[activeGroupIndex] count])
		activeBrushIndex = 0;
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setBorderType:NSGrooveBorder];
	[view setDocumentView:[[BrushView alloc] initWithMaster:self]];
	[view setBackgroundColor:[NSColor lightGrayColor]];
	if ([[view documentView] bounds].size.height > 3 * kBrushPreviewSize) {
		NSInteger yoff = MIN((activeBrushIndex / kBrushesPerRow) * kBrushPreviewSize, ([[self brushes] count] / kBrushesPerRow - 2) * kBrushPreviewSize);
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
		for (NSInteger i = 1; i < customGroups + 1; i++) {
			[brushGroupPopUp addItemWithTitle:groupNames[i]];
			[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
		}
	}
	[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (NSInteger i = customGroups + 1; i < [groupNames count]; i++) {
		[brushGroupPopUp addItemWithTitle:groupNames[i]];
		[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the brush that it is active
	[self setActiveBrushIndex:activeBrushIndex];
	
	// Set the window's properties
	[window setPanelStyle:SeaPanelStyleVertical];
	
	[[SeaController utilitiesManager] setBrushUtility: self for:document];
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:activeBrushIndex forKey:@"active brush"];
	[defaults setInteger:activeGroupIndex forKey:@"active brush group"];
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
	NSArray *tempArray;
	NSMutableArray *tempBrushArray;
	BOOL isDirectory;
	id tempBrush;
	
	// Create a dictionary of all brushes
	NSMutableDictionary *tmpBrushDict = [NSMutableDictionary dictionary];
	NSArray<NSString*> *files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"]];
	for (NSString *file in files) {
		NSString *tempPathA = [[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"] stringByAppendingPathComponent:file];
		if ([[tempPathA pathExtension] isEqualToString:@"gbr"]) {
			SeaBrush *tempBrush = [[SeaBrush alloc] initWithContentsOfFile:tempPathA];
			if (tempBrush) {
				[tmpBrushDict setObject:tempBrush forKey:tempPathA];
			}
		}
	}
	
	brushes = [tmpBrushDict copy];
	
	// Create the all group
	tempBrushArray = [[[brushes allValues] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
	groups = @[tempBrushArray];
	groupNames = @[LOCALSTR(@"all group", @"All")];
	
	// Create the custom groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"]];
	for (NSString *file in files) {
		NSString *tempPathA = [[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"];
		NSString *tempPathB = [tempPathA stringByAppendingPathComponent:file];
		if ([[tempPathB pathExtension] isEqualToString:@"txt"]) {
			tempArray = [NSArray arrayWithContentsOfFile:tempPathB];
			if (tempArray) {
				[tempBrushArray removeAllObjects];
				for (NSString *tmpNam in tempArray) {
					tempBrush = brushes[[tempPathA stringByAppendingPathComponent:tmpNam]];
					if (tempBrush) {
						[tempBrushArray addObject:tempBrush];
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
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"]];
	for (NSString *file in files) {
		NSString *tempPathA = [[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"] stringByAppendingPathComponent:file];
		[gFileManager fileExistsAtPath:tempPathA isDirectory:&isDirectory];
		if (isDirectory) {
			NSArray<NSString*> *tempArray = [gFileManager subpathsAtPath:tempPathA];
			NSMutableArray *tempBrushArray = [[NSMutableArray alloc] init];
			for (NSString *tmpNam in tempArray) {
				SeaBrush *tempBrush = brushes[[tempPathA stringByAppendingPathComponent:tmpNam]];
				if (tempBrush) {
					[tempBrushArray addObject:tempBrush];
				}
			}
			if ([tempBrushArray count] > 0) {
				[tempBrushArray sortUsingSelector:@selector(compare:)];
				groups = [groups arrayByAddingObject:tempBrushArray];
				groupNames = [groupNames arrayByAddingObject:[tempPathA lastPathComponent]];
			}
		}
	}
	
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

- (void)setActiveBrushIndex:(NSInteger)index
{
	SeaBrush *oldBrush = groups[activeGroupIndex][activeBrushIndex];
	SeaBrush *newBrush = groups[activeGroupIndex][index];
	
	[oldBrush deactivate];
	activeBrushIndex = index;
	[brushNameLabel setStringValue:[newBrush name]];
	[spacingSlider setIntValue:[newBrush spacing]];
	[spacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
	[newBrush activate];
}

- (NSArray *)brushes
{
	return groups[activeGroupIndex];
}


@end
