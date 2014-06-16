#import "BrushedDocumentController.h"

@implementation BrushedDocumentController

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	NSURL *brushesResources = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"brushes" isDirectory:YES];
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDirectoryURL:brushesResources];
	openPanel.allowedFileTypes = extensions;
	
	return [openPanel runModal];
}

@end
