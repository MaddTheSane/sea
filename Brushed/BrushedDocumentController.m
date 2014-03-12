#import "BrushedDocumentController.h"

@implementation BrushedDocumentController

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications/Seashore.app/Contents/Resources/brushes/"]];
	openPanel.allowedFileTypes = extensions;
	
	return [openPanel runModal];
}

@end
