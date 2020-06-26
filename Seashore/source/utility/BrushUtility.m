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
    brushes = [NSDictionary dictionary];
    [self loadBrushesFromPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"brushes"]];
	NSURL *userBrushes = [[[gFileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:@"Seashore"] URLByAppendingPathComponent:@"brushes" isDirectory:YES];
    [self loadBrushesFromPath:[userBrushes path]];
    [self createGroups];

}
- (void)loadBrushesFromPath:(NSString*)path
{
    NSArray *files;
    BOOL isDirectory;
    id brush;
    
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    // Create a dictionary of all brushes
    files = [gFileManager subpathsAtPath:path];
    for (NSInteger i = 0; i < [files count]; i++) {
        NSString *filepath =[path stringByAppendingPathComponent:files[i]];
        
        [gFileManager fileExistsAtPath:filepath isDirectory:&isDirectory];
        if(isDirectory){
            continue;
        }
        if ([[filepath pathExtension] caseInsensitiveCompare:@"gbr"] != NSOrderedSame) {
            continue;
        }
        
        brush = [[SeaBrush alloc] initWithContentsOfFile:filepath];
        if (brush) {
            [temp setValue:brush forKey:filepath];
        }
    }
    
    [temp setValuesForKeysWithDictionary:brushes];
    
    brushes = [NSDictionary dictionaryWithDictionary:temp];
}
- (void)createGroups
{
    // Create the all group
    NSArray *array = [[brushes allValues] sortedArrayUsingSelector:@selector(compare:)];
    groups = [NSArray arrayWithObject:array];
    groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
    
    NSMutableSet *dirs = [[NSMutableSet alloc] init];
    
    for(NSString *filepath in [brushes allKeys]){
        NSArray<NSString *> *comps = [filepath pathComponents];
        // directory is parent component of filename
        NSString *dir = [comps objectAtIndex:([comps count] - 2)];
        [dirs addObject:dir];
    }
    
    NSArray* sorted = [dirs allObjects];
    sorted = [sorted sortedArrayUsingSelector:@selector(compare:)];
    
    for(NSString* dirname in sorted){
        NSArray *groupBrushes = [[NSArray alloc] init];
        for(NSString *filepath in [brushes allKeys]){
            NSArray<NSString *> *comps = [filepath pathComponents];
            // directory is parent component of filename
            NSString *dir = [comps objectAtIndex:([comps count] - 2)];
            if([dirname isEqualToString:dir]){
                groupBrushes = [groupBrushes arrayByAddingObject:[brushes valueForKey:filepath]];
            }
        }
        if([groupBrushes count]>0){
            groupBrushes = [groupBrushes sortedArrayUsingSelector:@selector(compare:)];
            groups = [groups arrayByAddingObject:groupBrushes];
            groupNames = [groupNames arrayByAddingObject:dirname];
        }
    }
}

- (void)addBrushFromPath:(NSString *)path
{
    int i;
    
    SeaBrush *brush = [[SeaBrush alloc] initWithContentsOfFile:path];
    if(!brush){
        return;
    }
    
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:brushes];
    [copy setValue:brush forKey:path];
    
    brushes = [NSDictionary dictionaryWithDictionary:copy];
    
    [self createGroups];
    
    // Configure the pop-up menu
    [brushGroupPopUp removeAllItems];
    [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
    [[brushGroupPopUp itemAtIndex:0] setTag:0];
    [[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
    for (i = 1; i < [groupNames count]; i++) {
        [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
        [[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
    }
    [brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
    
    // Update utility
    [self setActiveBrushIndex:-1];
    [[view documentView] update];
    [view setNeedsDisplay:YES];
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

- (NSArray *)groupNames
{
    return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end
