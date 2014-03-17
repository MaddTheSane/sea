#import "TextureUtility.h"
#import "TextureView.h"
#import "SeaTexture.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "InfoPanel.h"
#import "TextTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

#ifdef TODO
#warning Make textures lazy, that is if they are not in the active group they are not memory
#endif

@implementation TextureUtility

- (id)init
{		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Load the textures
	[self loadTextures:NO];
	
	// Determine the currently active texture group
	if ([defaults objectForKey:@"active texture group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [defaults integerForKey:@"active texture group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active texture 	
	if ([defaults objectForKey:@"active texture"] == NULL)
		activeTextureIndex = 0;
	else
		activeTextureIndex = [defaults integerForKey:@"active texture"];
	if (activeTextureIndex < 0 || activeTextureIndex >= [groups[activeGroupIndex] count])
		activeTextureIndex = 0;
		
	// Set the opacity
	[opacitySlider setIntValue:100];
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = 255;
	
	return self;
}

- (void)awakeFromNib
{
	NSInteger yoff, i;
	
	[super awakeFromNib];

	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setBorderType:NSGrooveBorder];
	[view setDocumentView:[[TextureView alloc] initWithMaster:self]];
	[view setBackgroundColor:[NSColor lightGrayColor]];
	if ([[view documentView] bounds].size.height > 3 * kTexturePreviewSize) {
		yoff = MIN((activeTextureIndex / kTexturesPerRow) * kTexturePreviewSize, ([[self textures] count] / kTexturesPerRow - 2) * kTexturePreviewSize);
		[[view contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[view reflectScrolledClipView:[view contentView]];
	[view setLineScroll:kTexturePreviewSize];
	
	// Configure the pop-up menu
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:groupNames[0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:groupNames[i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the texture that it is active
	[self setActiveTextureIndex:-1];

	[[SeaController utilitiesManager] setTextureUtility: self for:document];
}

- (void)dealloc
{
	if ([view documentView]) [view documentView];
}

- (void)activate:(id)sender
{
	document = sender;
}

- (void)deactivate
{
	document = NULL;
}

- (void)shutdown
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:activeTextureIndex forKey:@"active texture"];
	[defaults setInteger:activeGroupIndex forKey:@"active texture group"];

}

- (void)update
{
	activeGroupIndex = [[textureGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	if (activeTextureIndex >= [groups[activeGroupIndex] count])
		activeTextureIndex = 0;
	[self setActiveTextureIndex:activeTextureIndex];
	[[view documentView] update];
	[view setNeedsDisplay:YES];
}

- (void)loadTextures:(BOOL)update
{
	NSArray *files, *subfiles, *newValues, *newKeys, *array;
	NSString *path;
	BOOL isDirectory;
	id texture;
	int i, j;
	
	// Create a dictionary of all textures
	textures = @{};
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/textures"]];
	for (i = 0; i < [files count]; i++) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:files[i]];
		texture = [[SeaTexture alloc] initWithContentsOfFile:path];
		if (texture) {
			newKeys = [[textures allKeys] arrayByAddingObject:path];
			newValues = [[textures allValues] arrayByAddingObject:texture];
			textures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
		}
	}
	
	// Create the all group
	array = [[textures allValues] sortedArrayUsingSelector:@selector(compare:)];
	groups = @[array];
	groupNames = @[LOCALSTR(@"all group", @"All")];
	
	// Create the other groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/textures"]];
	[files sortedArrayUsingSelector:@selector(compare:)];
	for (i = 0; i < [files count]; i++) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:files[i]];
		[gFileManager fileExistsAtPath:path isDirectory:&isDirectory];
		if (isDirectory) {
			path = [path stringByAppendingString:@"/"];
			subfiles = [gFileManager subpathsAtPath:path];
			array = @[];
			for (j = 0; j < [subfiles count]; j++) {
				texture = textures[[path stringByAppendingString:subfiles[j]]];
				if (texture) {
					array = [array arrayByAddingObject:texture];
				}
			}
			if ([array count] > 0) {
				array = [array sortedArrayUsingSelector:@selector(compare:)];
				groups = [groups arrayByAddingObject:array];
				groupNames = [groupNames arrayByAddingObject:[path lastPathComponent]];
			}
		}
	}
	
	// Retain the groups and groupNames
	
	// Update utility if requested
	if (update) [self update];
}

- (void)addTextureFromPath:(NSString *)path
{
	NSArray *files, *subfiles, *newValues, *newKeys, *oldValues, *oldKeys, *array;
	NSString *tpath;
	BOOL isDirectory;
	id texture;
	int i, j;
	
	// Release any existing textures
	
	// Update dictionary of all textures
	if (textures[path]) {
		newKeys = @[];
		newValues = @[];
		oldKeys = [textures allKeys];
		oldValues = [textures allValues];
		for (i = 0; i < [oldKeys count]; i++) {
			if (![path isEqualToString:oldKeys[i]]) {
				newKeys = [newKeys arrayByAddingObject:oldKeys[i]];
				newValues = [newValues arrayByAddingObject:oldValues[i]];
			}
		}
	}
	else {
		newKeys = [textures allKeys];
		newValues = [textures allValues];
	}
	texture = [[SeaTexture alloc] initWithContentsOfFile:path];
	if (texture) {
		newKeys = [newKeys arrayByAddingObject:path];
		newValues = [newValues arrayByAddingObject:texture];
		textures = [NSDictionary dictionaryWithObjects:newValues forKeys:newKeys];
	}
	
	// Create the all group
	array = [[textures allValues] sortedArrayUsingSelector:@selector(compare:)];
	groups = @[array];
	groupNames = @[LOCALSTR(@"all group", @"All")];
	
	// Create the other groups
	files = [gFileManager subpathsAtPath:[[gMainBundle resourcePath] stringByAppendingString:@"/textures"]];
	[files sortedArrayUsingSelector:@selector(compare:)];
	for (i = 0; i < [files count]; i++) {
		tpath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/textures/"] stringByAppendingString:files[i]];
		[gFileManager fileExistsAtPath:tpath isDirectory:&isDirectory];
		if (isDirectory) {
			tpath = [tpath stringByAppendingString:@"/"];
			subfiles = [gFileManager subpathsAtPath:tpath];
			array = @[];
			for (j = 0; j < [subfiles count]; j++) {
				texture = textures[[tpath stringByAppendingString:subfiles[j]]];
				if (texture) {
					array = [array arrayByAddingObject:texture];
				}
			}
			if ([array count] > 0) {
				array = [array sortedArrayUsingSelector:@selector(compare:)];
				groups = [groups arrayByAddingObject:array];
				groupNames = [groupNames arrayByAddingObject:[tpath lastPathComponent]];
			}
		}
	}
	
	// Retain the groups and groupNames
	
	// Configure the pop-up menu
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:groupNames[0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:groupNames[i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Update utility
	[self setActiveTextureIndex:-1];
	[[view documentView] update];
	[view setNeedsDisplay:YES];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (IBAction)changeOpacity:(id)sender
{
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = [opacitySlider intValue] * 2.55;
}

- (int)opacity
{
	return opacity;
}

- (id)activeTexture
{
	return groups[activeGroupIndex][activeTextureIndex];
}

- (int)activeTextureIndex
{
	if ([[SeaController seaPrefs] useTextures])
		return activeTextureIndex;
	else
		return -1;
}

- (void)setActiveTextureIndex:(int)index
{
	id oldTexture;
	id newTexture;
	
	if (index == -1) {
		[[SeaController seaPrefs] setUseTextures:NO];
		[textureNameLabel setStringValue:@""];
		[opacitySlider setEnabled:NO];
		[view setNeedsDisplay:YES];
	}
	else {
		oldTexture = groups[activeGroupIndex][activeTextureIndex];
		newTexture = groups[activeGroupIndex][index];
		[oldTexture deactivate];
		activeTextureIndex = index;
		[[SeaController seaPrefs] setUseTextures:YES];
		[textureNameLabel setStringValue:[newTexture name]];
		[opacitySlider setEnabled:YES];
		[newTexture activate];
		[[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
		[(TextTool *)[[document tools] getTool:kTextTool] preview:NULL];
	}
}

- (NSArray *)textures
{
	return groups[activeGroupIndex];
}

- (NSArray *)groupNames
{
	return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end
