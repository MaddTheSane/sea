#import "SeaDocumentController.h"
#import "SeaPrefs.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "Units.h"

@implementation SeaDocumentController
@synthesize type;
@synthesize height;
@synthesize width;
@synthesize resolution;
@synthesize opaque;
@synthesize units;

- (instancetype)init
{
	if (self = [super init]) {
		stopNotingRecentDocuments = NO;
	}
	
	return self;
}

- (void)awakeFromNib
{
	editableTypes = [[NSMutableDictionary alloc] init];
	viewableTypes = [[NSMutableDictionary alloc] init];
	
	// The document controller is responsible for tracking document types
	// In addition, as it's in control of open, it also must know the types for import and export
	NSArray *allDocumentTypes = [[[NSBundle mainBundle] infoDictionary]
							  valueForKey:@"CFBundleDocumentTypes"];
	for (NSDictionary *typeDict in allDocumentTypes) {
		NSMutableSet<NSString*> *assembly = [NSMutableSet set];

		[assembly addObjectsFromArray:typeDict[@"CFBundleTypeExtensions"]];
		{
			NSArray *infoPlistOSType = typeDict[@"CFBundleTypeOSTypes"];
			NSMutableArray<NSString*> *osTypeArr = [[NSMutableArray alloc] initWithCapacity:infoPlistOSType.count];
			for (id osTyp in infoPlistOSType) {
				if ([osTyp isKindOfClass:[NSNumber class]]) {
					NSString *newType = NSFileTypeForHFSTypeCode([(NSNumber*)osTyp unsignedIntValue]);
					[osTypeArr addObject:newType];
				} else if ([osTyp isKindOfClass:[NSString class]]) {
					NSString *newType = NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((__bridge CFStringRef _Nonnull)(osTyp)));
					[osTypeArr addObject:newType];
				}
			}
			[assembly addObjectsFromArray:osTypeArr];
		}
		[assembly addObjectsFromArray:typeDict[@"LSItemContentTypes"]];
		
		NSString* key = typeDict[@"CFBundleTypeName"];
		[assembly addObject:key];
				
		NSString *role = typeDict[@"CFBundleTypeRole"];
		if ([role isEqual:@"Editor"]) {
			editableTypes[key] = assembly;
		} else if ([role isEqual:@"Viewer"]) {
			viewableTypes[key] = assembly;
		}
	}
}

- (IBAction)newDocument:(id)sender
{		
	// Set paper name
	if ([[NSPrintInfo sharedPrintInfo] respondsToSelector:@selector(localizedPaperName)]) {
		NSMenuItem *menuItem = [templatesMenu itemAtIndex:[templatesMenu indexOfItemWithTag:4]];
		NSString *string = [NSString stringWithFormat:@"%@ (%@)", LOCALSTR(@"paper size", @"Paper size"), [[NSPrintInfo sharedPrintInfo] localizedPaperName]];
		[menuItem setTitle:string];
	}

	// Display the panel for configuring
	units = [[SeaController seaPrefs] newUnits];
	[unitsMenu selectItemAtIndex: units];
	[resMenu selectItemAtIndex:[(SeaPrefs *)[SeaController seaPrefs] resolution]];
	[modeMenu selectItemAtIndex:[(SeaPrefs *)[SeaController seaPrefs] mode]];
	resolution = (int)[[resMenu selectedItem] tag];
	IntSize size = [[SeaController seaPrefs] size];
	[widthInput setStringValue:SeaStringFromPixels(size.width, units, resolution)];
	[heightInput setStringValue:SeaStringFromPixels(size.height, units, resolution)];
	[heightUnits setStringValue:SeaUnitsString(units)];
	[backgroundCheckbox setState:[(SeaPrefs *)[SeaController seaPrefs] transparentBackground]];
	
	// Set up the recents menu
	NSArray *recentDocs = [super recentDocumentURLs];
	if ([recentDocs count]) {
		[recentMenu setEnabled:YES];
		for (NSURL *docURL in recentDocs) {
			NSString *path = [docURL path];
			NSString *filename = docURL.lastPathComponent;
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile: path];
			[recentMenu addItemWithTitle: filename];
			[[recentMenu itemAtIndex:[recentMenu numberOfItems] - 1] setRepresentedObject:path];
			[[recentMenu itemAtIndex:[recentMenu numberOfItems] - 1] setImage: image];
		}
	} else {
		[recentMenu setEnabled:NO];
	}

	
	[newPanel center];
	[newPanel makeKeyAndOrderFront:self];
}

- (IBAction)openDocument:(id)sender
{
	[newPanel orderOut:self];
	[super openDocument:sender];
}

- (id)openNonCurrentFile:(NSString *)path
{
	id newDocument;
	
	stopNotingRecentDocuments = YES;
	newDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:path display:YES];
	stopNotingRecentDocuments = NO;
	[newDocument setCurrent:NO];
	
	return newDocument;
}

- (IBAction)openRecent:(id)sender
{
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[sender selectedItem] representedObject]] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		//do nothing
	}];
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument
{
	if (stopNotingRecentDocuments == NO && [(SeaDocument *)aDocument current]) {
		[super noteNewRecentDocument:aDocument];
	}
}

- (IBAction)createDocument:(id)sender
{
	// Determine the resolution
	resolution = (int)[[resMenu selectedItem] tag];

	// Parse width and height	
	width = SeaPixelsFromFloat([widthInput floatValue], units, resolution); 
	height = SeaPixelsFromFloat([heightInput floatValue], units, resolution); 
			
	// Don't accept rediculous heights or widths
	if (width < kMinImageSize || width > kMaxImageSize) { NSBeep(); return; }
	if (height < kMinImageSize || height > kMaxImageSize) { NSBeep(); return; }
	
	// Determine everything else
	type = (int)[modeMenu indexOfSelectedItem];
	opaque = ![backgroundCheckbox state];

	// Create a new document
	[super newDocument:sender];
}

- (IBAction)changeToTemplate:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	
	NSInteger selectedTag = [[templatesMenu selectedItem] tag];
	NSInteger res = [[resMenu selectedItem] tag];
	switch (selectedTag) {
		case 1:
			size = [[SeaController seaPrefs] size];
			units = [[SeaController seaPrefs] newUnits];
			[unitsMenu selectItemAtIndex: units];
			res = [[SeaController seaPrefs] resolution];
			[resMenu selectItemAtIndex:res];
			break;
			
		case 2:
			pboard = [NSPasteboard generalPasteboard];
			availableType = [pboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
			if (availableType) {
				image = [[NSImage alloc] initWithData:[pboard dataForType:availableType]];
				size = NSSizeMakeIntSize([image size]);
			} else {
				NSBeep();
				return;
			}
			
			break;
			
		case 3:
			size = NSSizeMakeIntSize([[NSScreen mainScreen] frame].size);
			units = kPixelUnits;
			[unitsMenu selectItemAtIndex: kPixelUnits];
			break;
			
		case 4:
			paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
			paperSize.height -= [[NSPrintInfo sharedPrintInfo] topMargin] + [[NSPrintInfo sharedPrintInfo] bottomMargin];
			paperSize.width -= [[NSPrintInfo sharedPrintInfo] leftMargin] + [[NSPrintInfo sharedPrintInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			units = kInchUnits;
			[unitsMenu selectItemAtIndex: kInchUnits];
			size.width = (float)size.width * (res / 72.0);
			size.height = (float)size.height * (res / 72.0);
			break;
		case 1000:
			/* Henry, add "Add..." item functionality here. */
			break;
			
		case 1001:
			/* Henry, add "Editor..." item functionality here. */
			break;
	}
	
	if (selectedTag != 1000 && selectedTag != 1001) {
		[widthInput setStringValue:SeaStringFromPixels(size.width, units, (int)res)];
		[heightInput setStringValue:SeaStringFromPixels(size.height, units, (int)res)];
		[heightUnits setStringValue:SeaUnitsString(units)];
	}
}

- (IBAction)changeUnits:(id)sender
{
	IntSize size = IntMakeSize(0, 0);
	int res = (int)[[resMenu selectedItem] tag];

	size.height =  SeaPixelsFromFloat([heightInput floatValue],units,res);
	size.width =  SeaPixelsFromFloat([widthInput floatValue],units,res);

	units = (int)[[unitsMenu selectedItem] tag];
	[widthInput setStringValue:SeaStringFromPixels(size.width, units, res)];
	[heightInput setStringValue:SeaStringFromPixels(size.height, units, res)];
	[heightUnits setStringValue:SeaUnitsString(units)];
}

- (void)addDocument:(NSDocument *)document
{
	[newPanel orderOut:self];
	[super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document
{
	[super removeDocument:document];
}

@synthesize editableTypes;
@synthesize viewableTypes;

- (NSArray*)readableTypes
{
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:editableTypes.count + viewableTypes.count];
	for (NSSet *obj in editableTypes.objectEnumerator) {
		[array addObjectsFromArray:[obj allObjects]];
	}
	
	for (NSSet *obj in viewableTypes.objectEnumerator) {
		[array addObjectsFromArray:[obj allObjects]];
	}
	return [array copy];
}

//- (NSArray *)fileExtensionsFromType:(NSString *)typeName
//{
//	return @[];
//}

- (BOOL)type:(NSString *)aType isContainedInDocType:(NSString*) key
{
	// We need to special case these for some reason, I don't know why
	//if([key isEqual:@"Gimp image"] &&
	//   (![aType caseInsensitiveCompare:@"com.gimp.xcf"] ||
	//    ![aType caseInsensitiveCompare:@"net.sourceforge.xcf"] ||
	//	![aType caseInsensitiveCompare:@"Gimp Document"])){
	//	return YES;
	//}
	
	NSSet<NSString*> *set = editableTypes[key];
	if(!set){
		set = viewableTypes[key];
		// That's wierd, someone has passed in an invalid type
		if(!set){
			NSLog(@"Invalid key passed to SeaDocumentController: <%@> \n Investigating type: <%@>", key, aType);
			return NO;
		}
	}
	
	for (NSString *candidate in set) {
		// I think we don't care about case in types
		if ([aType caseInsensitiveCompare:candidate] == NSOrderedSame) {
			return YES;
		}
	}
	return NO;
}

@end
