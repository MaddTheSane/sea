#import <Foundation/Foundation.h>
#import "SeaPlugins.h"
#import "PluginClass.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaTools.h"
#import "EffectTool.h"
#import "ToolboxUtility.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "CIAffineTransformClass.h"
#import "EffectOptions.h"

extern BOOL useAltiVec;

@implementation SeaPlugins
@synthesize pointPluginsNames;
@synthesize pointPlugins;

static BOOL checkRun(NSString *path, NSString *file)
{
	NSDictionary *infoDict;
	BOOL canRun;
	id value;
	
	// Get dictionary
	canRun = YES;
	{
		NSString *bundDir = [path stringByAppendingPathComponent:file];
		NSBundle *bund = [NSBundle bundleWithPath:bundDir];
		infoDict = [bund infoDictionary];
	}
	
	if (!infoDict) {
		infoDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Contents/Info.plist", path, file]];
	}
	
	// Check special
	value = infoDict[@"SpecialPlugin"];
	if (value != NULL) {
		if ([value boolValue]) {
			canRun = NO;
		}
	}
	
	// Check PPC
#ifndef __ppc__
	value = infoDict[@"PPCOnly"];
	if (value != NULL) {
		if ([value boolValue]) {
			canRun = NO;
		}
	}
#endif
	
	// Check Intel
#if !(defined(__i386__) || defined(__x86_64__))
	value = infoDict[@"IntelOnly"];
	if (value != NULL) {
		if ([value boolValue]) {
			canRun = NO;
		}
	}
#endif
	
	// Check AltiVec or SSE
#ifdef __ppc__
	value = [infoDict objectForKey:@"AltiVecOrSSERequired"];
	if (value != NULL) {
		if ([value boolValue]) {
			if (useAltiVec == NO) canRun = NO;
		}
	}
#endif
	
	// Check system version
	value = infoDict[@"LSMinimumSystemVersion"];
	if (value == nil) {
		value = infoDict[@"MinSystemVersion"];
	}
	if (value != NULL && [value isKindOfClass:[NSString class]]) {
		do {
			NSOperatingSystemVersion sysVers;
			NSScanner *versScanner = [NSScanner scannerWithString:value];
			versScanner.charactersToBeSkipped = [NSCharacterSet punctuationCharacterSet];
			int toScan;
			if (![versScanner scanInt:&toScan]) {
				break;
			}
			sysVers.majorVersion = toScan;
			if (![versScanner scanInt:&toScan]) {
				break;
			}
			sysVers.minorVersion = toScan;
			if ([versScanner scanInt:&toScan]) {
				sysVers.patchVersion = toScan;
			} else {
				sysVers.patchVersion = 0;
			}
			
			canRun = canRun && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:sysVers];
		} while (0);
	}
	
	return canRun;
}

- (instancetype)init
{
	NSString *pluginsPath, *pre_files_name, *files_name;
	NSArray *pre_files;
	NSMutableArray *files;
	NSBundle *bundle;
	id<SeaPluginClass> plugin;
	int i, j, found_id;
	BOOL success, found, can_run;
	NSRange range, next_range;
	
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	// Set the last effect to nothing
	lastEffect = -1;
	
	// Add standard plug-ins
	plugins = [[NSMutableArray alloc] init];
	pluginsPath = [gMainBundle builtInPlugInsPath];
	pre_files = [gFileManager contentsOfDirectoryAtPath:pluginsPath error:NULL];
	files = [NSMutableArray arrayWithCapacity:[pre_files count]];
	for (i = 0; i < [pre_files count]; i++) {
		pre_files_name = pre_files[i];
		if ([pre_files_name hasSuffix:@".bundle"] && ![pre_files_name hasSuffix:@"+.bundle"]) {
			can_run = checkRun(pluginsPath, pre_files_name);
			if (can_run) [files addObject:pre_files_name];
		}
	}
	
	// Add plus plug-ins
	for (i = 0; i < [pre_files count]; i++) {
		pre_files_name = pre_files[i];
		if ([pre_files_name hasSuffix:@"+.bundle"]) {
			found = NO;
			range.location = 0;
			range.length = [pre_files_name length] - (strlen("+.bundle") - 1);
			found_id = -1;
			for (j = 0; j < [files count] && !found; j++) {
				files_name = files[j];
				next_range.location = 0;
				next_range.length = [files_name length] - (strlen(".bundle") - 1);
				if ([[files_name substringWithRange:next_range] isEqualToString:[pre_files_name substringWithRange:range]]) {
					found = YES;
					found_id = j;
				}
			}
			can_run = checkRun(pluginsPath, pre_files_name);
			if (can_run) {
				if (found)
					files[found_id] = pre_files_name;
				else
					[files addObject:pre_files_name];
			}
		}
	}
	
	// Check added plug-ins
	ciAffineTransformIndex = -1;
	for (NSString *file in files) {
		bundle = [NSBundle bundleWithPath:[pluginsPath stringByAppendingPathComponent:file]];
		if (bundle && [bundle principalClass]) {
			success = NO;
			if (![[bundle principalClass] instancesRespondToSelector:@selector(initWithManager:)]) {
				continue;
			}
			plugin = [[[bundle principalClass] alloc] initWithManager:self];
			if ([plugin respondsToSelector:@selector(sanity)] && [[plugin sanity] isEqualToString:@"Seashore Approved (Bobo)"]) {
				[plugins addObject:plugin];
				success = YES;
			}
		}
	}
	
	// Sort plug-ins
	[plugins sortUsingComparator:^NSComparisonResult(id<SeaPluginClass> obj1, id<SeaPluginClass> obj2) {
		NSComparisonResult result;
		
		result = [obj1.groupName caseInsensitiveCompare:obj2.groupName];
		if (result == NSOrderedSame) {
			result = [obj1.name caseInsensitiveCompare:obj2.name];
		}
		
		return result;
	}];

	// Determine affine transform plug-in
	for (i = 0; i < [plugins count]; i++) {
		plugin = plugins[i];
		if ([plugin respondsToSelector:@selector(runAffineTransform:withImage:spp:width:height:opaque:newWidth:newHeight:)]) {
			if (ciAffineTransformIndex == -1) {
				ciAffineTransformIndex = i;
			} else {
				NSLog(@"Multiple plug-ins are affine transform capable (using first): %@ %@", files[ciAffineTransformIndex], files[i]);
			}
		}
	}
	
	return self;
}

- (void)awakeFromNib
{
	id menuItem, submenuItem;
	NSMenu *submenu;
	id plugin;
	int i;
	
	// Set up
	pointPlugins = @[];
	pointPluginsNames = @[];
	    
	// Configure all plug-ins
	for (i = 0; i < [plugins count] && i < 7500; i++) {
		plugin = plugins[i];
        
		// If the plug-in is a basic plug-in add it to the effects menu
		if ([(id <SeaPluginClass>)plugin type] == kBasicPlugin) {
			
			// Add or find group submenu
			submenuItem = [effectMenu itemWithTitle:[plugin groupName]];
			if (submenuItem == NULL) {
				submenuItem = [[NSMenuItem alloc] initWithTitle:[plugin groupName] action:NULL keyEquivalent:@""];
				[effectMenu insertItem:submenuItem atIndex:[effectMenu numberOfItems] - 2];
				submenu = [[NSMenu alloc] initWithTitle:[submenuItem title]];
				[submenuItem setSubmenu:submenu];
			}
			else {
				submenu = [submenuItem submenu];
			}
			
			// Add plug-in to group
			menuItem = [submenu itemWithTitle:[plugin name]];
			if (menuItem == NULL) {
				menuItem = [[NSMenuItem alloc] initWithTitle:[plugin name] action:@selector(run:) keyEquivalent:@""];
				[menuItem setTarget:self];
				[submenu addItem:menuItem];
				[menuItem setTag:i + 10000];
			}
			
		}
		else if ([(id <SeaPluginClass>)plugin type] == kPointPlugin) {
			pointPluginsNames = [pointPluginsNames arrayByAddingObject:[NSString stringWithFormat:@"%@ / %@", [plugin groupName], [plugin name]]];
			pointPlugins = [pointPlugins arrayByAddingObject:plugin];
		}
		
	}
	
	// Finish off
	
	// Correct effect tool
	[[[SeaController utilitiesManager] toolboxUtilityFor:gCurrentDocument] setEffectEnabled:([pointPluginsNames count] != 0)];

	// Register to recieve the terminate message when Seashore quits
	[controller registerForTermination:self];
}


- (void)terminate
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions: kEffectTool] selectedRow] forKey:@"effectIndex"];
}

- (id)affinePlugin
{
	if (ciAffineTransformIndex >= 0)
		return plugins[ciAffineTransformIndex];
	else
		return nil;
}

- (PluginData*)data
{
	return [gCurrentDocument pluginData];
}

- (IBAction)run:(id)sender
{
	[(id <SeaPluginClass>)plugins[[sender tag] - 10000] run];
	lastEffect = [sender tag] - 10000;
}

- (IBAction)reapplyEffect:(id)sender
{
	[plugins[lastEffect] reapply];
}

- (void)cancelReapply
{
	lastEffect = -1;
}

- (BOOL)hasLastEffect
{
	return lastEffect != -1 && [plugins[lastEffect] canReapply];
}

- (id)activePointEffect
{
	return pointPlugins[[[[[SeaController utilitiesManager] optionsUtilityFor:gCurrentDocument] getOptions: kEffectTool] selectedRow]];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	SeaDocument *document = gCurrentDocument;
	
	// Never when there is no document
	if (document == NULL)
		return NO;
	
	// End the line drawing
	[[document helpers] endLineDrawing];
	
	// Never when the document is locked
	if ([document locked])
		return NO;
	
	// Never if we are told not to
	if ([menuItem tag] >= 10000 && [menuItem tag] < 17500) {
		if (![plugins[[menuItem tag] - 10000] validateMenuItem:menuItem])
			return NO;
	}

	return YES;
}

@end
