#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaBrush.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaSelection.h"
#import "SeaWarning.h"
#import "SeaPrefs.h"
#import "SeaHelp.h"
#import "SeaTools.h"
#import "SeaDocumentController.h"

static SeaController *seaController;

@implementation SeaController
@synthesize licenseWindow;
@synthesize seaHelp;
@synthesize seaPlugins;
@synthesize seaPrefs;
@synthesize seaProxy;
@synthesize seaWarning;
@synthesize utilitiesManager;

- (instancetype)init
{
	if (self = [super init]) {
	// Remember ourselves
	seaController = self;
	
	// Creates an array which can store objects that wish to recieve the terminate: message
	terminationObjects = [[NSMutableArray alloc] init];
	
	// Specify ourselves as NSApp's delegate
	[NSApp setDelegate:self];

	// We want to know when ColorSync changes
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSyncChanged:) name:@"AppleColorSyncPreferencesChangedNotification" object:NULL];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *crashReport = [[[[fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:@"Logs"] URLByAppendingPathComponent:@"CrashReporter"] URLByAppendingPathComponent:@"Seashore.crash.log" isDirectory:NO];

	// Run initial tests
	if ([seaPrefs firstRun] && [crashReport checkResourceIsReachableAndReturnError:NULL]) {
		if ([fileManager trashItemAtURL:crashReport resultingItemURL:NULL error:NULL]) {
			[seaWarning addMessage:LOCALSTR(@"old crash report message", @"Seashore has moved its old crash report to the Trash so that it will be deleted next time you empty the trash.") level:SeaWarningImportanceModerate];
		}
	}
	/*
	[seaWarning addMessage:LOCALSTR(@"beta message", @"Seashore is still under development and may contain bugs. Please make sure to only work on copies of images as there is the potential for corruption. Also please report any bugs you find.") level:[seaPrefs firstRun] ? kHighImportance : kVeryLowImportance];
	*/
	
	// Check run count
	/*
	if ([seaPrefs runCount] == 25) {
		if (NSRunAlertPanel(LOCALSTR(@"feedback survey title", @"Seashore Feedback Survey"), LOCALSTR(@"feedback survey body", @"In order to improve the next release of Seashore we are asking users to participate in a survey. The survey is only one page long and can be accessed by clicking the \"Run Survey\" button. This message should not trouble you again."), LOCALSTR(@"feedback survey button", @"Run Survey"), LOCALSTR(@"cancel", @"Cancel"), NULL) == NSAlertDefaultReturn) {
			[seaHelp goSurvey:NULL];
		}
	}
	*/
	
	// Check for update
	if ([seaPrefs checkForUpdates]) {
		[seaHelp checkForUpdate:nil];
	}
}

+ (id)utilitiesManager
{
	return [seaController utilitiesManager];
}

+ (id)seaPlugins
{
	return [seaController seaPlugins];
}

+ (id)seaPrefs
{
	return [seaController seaPrefs];
}

+ (id)seaProxy
{
	return [seaController seaProxy];
}

+ (id)seaHelp
{
	return [seaController seaHelp];
}

+ (id)seaWarning
{
	return [seaController seaWarning];
}

- (IBAction)revert:(id)sender
{
	NSURL *fileURL = [gCurrentDocument fileURL];
	NSRect frame = [[[gCurrentDocument windowControllers][0] window] frame];
	
	// Question whether to proceed with reverting
	if (NSRunAlertPanel(LOCALSTR(@"revert title", @"Revert"), LOCALSTR(@"revert body", @"\"%@\" has been edited. Are you sure you want to undo changes?"), LOCALSTR(@"revert", @"Revert"), LOCALSTR(@"cancel", @"Cancel"), NULL, [gCurrentDocument displayName]) == NSAlertDefaultReturn) {
		
		// Close the document and reopen it
		[gCurrentDocument close];
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:NO completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
			NSWindow *window = [[document windowControllers][0] window];
			[window setFrame:frame display:YES];
			[window makeKeyAndOrderFront:self];
		}];
	}
}

- (IBAction)editLastSaved:(id)sender
{
	NSFileManager *fm = [NSFileManager defaultManager];
	SeaDocument *originalDocument, *currentDocument = gCurrentDocument;
	NSString *old_path = [[currentDocument fileURL] path], *new_path = NULL;
	int i;
	BOOL done;
	
	// Find a unique new name
	done = NO;
	for (i = 1; i <= 64 && !done; i++) {
		if (i == 1) {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original).%@", [old_path pathExtension]];
			if ([fm fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
		else {
			new_path = [[old_path stringByDeletingPathExtension] stringByAppendingFormat:@" (Original %d).%@", i, [old_path pathExtension]];
			if ([fm fileExistsAtPath:new_path] == NO) {
				done = YES;
			}
		}
	}
	if (!done) {
		NSLog(@"Can't find suitable filename (last tried: %@)", new_path);
		return;
	}
	
	// Copy the contents on disk and open so the last saved version can be edited
	if ([fm copyItemAtPath:old_path toPath:new_path error:NULL]) {
		originalDocument = [[SeaDocumentController sharedDocumentController] openNonCurrentFile:new_path];
	} else {
		NSRunAlertPanel(LOCALSTR(@"locked title", @"Operation Failed"), LOCALSTR(@"locked body", @"The \"Compare to Last Saved\" operation failed. The most likely cause for this is that the disk the original is kept on is full or read-only."), LOCALSTR(@"ok", @"OK"), NULL, NULL, [gCurrentDocument displayName]);
		return;
	}
	
	// Finally remove the file we just created
	[fm removeItemAtPath:new_path error:NULL];
}

- (void)colorSyncChanged:(NSNotification *)notification
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	
	// Tell all documents to update their colour worlds
	for (SeaDocument *doc in documents) {
		[[doc whiteboard] updateColorWorld];
	}
}

- (IBAction)showLicense:(id)sender
{
	[licenseWindow setLevel:NSFloatingWindowLevel];
	[licenseWindow makeKeyAndOrderFront:sender];
}

- (IBAction)newDocumentFromPasteboard:(id)sender
{
	NSDocument *document;
	
	// Ensure that the document is valid
	if(![[NSPasteboard generalPasteboard] availableTypeFromArray:@[NSPasteboardTypeTIFF]]){
		NSBeep();
		return;
	}
	
	// We can now create the new document
	document = [[SeaDocument alloc] initWithPasteboard];
	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
}

- (void)registerForTermination:(id<SSKTerminatable>)object
{
	[terminationObjects addObject:object];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Inform those that wish to know
	for (id<SSKTerminatable> thePrefs in terminationObjects) {
		[thePrefs terminate];
	}
	
	// Save the changes in preferences
	[defaults synchronize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app
{
	return [self.seaPrefs openUntitled];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)app
{
	[[SeaDocumentController sharedDocumentController] newDocument:self];
	
	return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	id availableType;
	
	switch ([menuItem tag]) {
		case 175:
			return gCurrentDocument && [gCurrentDocument fileURL] && [gCurrentDocument isDocumentEdited] && [gCurrentDocument current];
			break;
			
		case 176:
			return gCurrentDocument && [gCurrentDocument fileURL] && [gCurrentDocument current];
			break;
			
		case 400:
			availableType = [[NSPasteboard generalPasteboard] availableTypeFromArray:@[NSPasteboardTypeTIFF]];
			if (availableType)
				return YES;
			else
				return NO;
			break;
	}
	
	return YES;
}

+ (id)seaController
{
	return seaController;
}

@end
