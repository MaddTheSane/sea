#import "TextureExporter.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "SeaDocument.h"

NS_ENUM(int) {
	kExistingCategoryButton,
	kNewCategoryButton
};

@implementation TextureExporter

- (void)awakeFromNib
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)exportAsTexture:(id)sender
{
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];
	NSString *path;

	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
	
	// Determine the path
	if ([existingCategoryRadio state] == NSOnState) {
		path = [[[gMainBundle resourcePath] stringByAppendingPathComponent:@"textures"] stringByAppendingPathComponent:groupNames[[categoryTable selectedRow]]];
	}
	else {
		path = [[[gMainBundle resourcePath] stringByAppendingPathComponent:@"textures"] stringByAppendingPathComponent:[categoryTextbox stringValue]];
		[gFileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	path = [[path stringByAppendingPathComponent:[nameTextbox stringValue]] stringByAppendingPathExtension:@"png"];
	
	// Write document
	NSError *err = nil;
	if (![document writeToURL:[NSURL fileURLWithPath:path] ofType:(NSString*)kUTTypePNG error:&err]) {
		[[NSAlert alertWithError:err] runModal];
	}
	//[document writeToFile:path ofType:@"Portable Network Graphics image"];
	
	// Refresh textures
	[[[SeaController utilitiesManager] textureUtilityFor:document] addTextureFromPath:path];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)existingCategoryClick:(id)sender
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)newCategoryClick:(id)sender
{
	[self selectButton:kNewCategoryButton];
}

- (void)selectButton:(int)button
{
	switch (button) {
		case kExistingCategoryButton:
			[existingCategoryRadio setState:NSOnState];
			[newCategoryRadio setState:NSOffState];
			[categoryTable setEnabled:YES];
			[categoryTextbox setEnabled:NO];
		break;
		case kNewCategoryButton:
			[existingCategoryRadio setState:NSOffState];
			[newCategoryRadio setState:NSOnState];
			[categoryTable setEnabled:NO];
			[categoryTextbox setEnabled:YES];
		break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];

	return groupNames[row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];

	return [groupNames count];
}

@end
