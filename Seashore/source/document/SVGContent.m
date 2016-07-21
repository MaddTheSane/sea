#import "SVGContent.h"
#import "SVGLayer.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "SeaWarning.h"

IntSize getDocumentSize(char *path)
{
	FILE *file;
	char header[2056], dstr[128];
	IntSize result = IntMakeSize(0, 0);
	int ivalue;
	char *pos, *value = NULL;
	BOOL quote;
	int tagID;
	size_t size;
		
	file = fopen(path, "rb");
	fread(header, sizeof(char), 2048, file);
	pos = header;
	quote = NO;
	tagID = 0;
	
	while (pos - header < 2048 && (result.width == 0 || result.height == 0)) {

		if (quote) {
			if (tagID == 1 || tagID == 2) {
				
				ivalue = -1;
				size = pos - value;
				if (size > 127) size = 127;
				if (strncmp(pos, "pt", 2) == 0 || pos[0] == '"') {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 1.25;
				}
				else if (strncmp(pos, "pc", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 15.0;
				}
				else if (strncmp(pos, "mm", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 3.543307;
				}
				else if (strncmp(pos, "cm", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 35.43307;
				}
				else if (strncmp(pos, "in", 2) == 0) {
					strncpy(dstr, value, size);
					dstr[size] = 0x00;
					ivalue = (int)strtod(dstr, NULL) * 90.0;
				}
				if (ivalue != -1) {
					if (tagID == 1)
						result.width = ivalue;
					else
						result.height = ivalue;
					tagID = 0;
				}
			
			}				
		}
			
	
		if (pos[0] == '"') {
			
			if (quote) {
				quote = NO;
				tagID = 0;
			}
			else {
				quote = YES;
				value = pos + 1;
			}
		
		}
		
		if (!quote) {
			if (strncmp(pos, "width", 5) == 0) {
				tagID = 1;
			}
			if (strncmp(pos, "height", 6) == 0) {
				tagID = 2;
			}
		}
		
		pos++;
	
	}
	
	fclose(file);
	
	return result;
}

@implementation SVGContent

+ (BOOL)typeIsViewable:(NSString *)aType
{
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType: @"SVG document"];
}

- (instancetype)initWithDocument:(id)doc contentsOfFile:(NSString *)path
{
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	Class svgRep = NSClassFromString(@"SVGImageRep");
	if (!svgRep) {
		NSBundle *svgBundle = [NSBundle bundleWithPath:[[gMainBundle builtInPlugInsPath] stringByAppendingPathComponent:@"SVGImageRep.bundle"]];
		if (svgBundle || [svgBundle load]) {
			svgRep = NSClassFromString(@"SVGImageRep");
		}
	}
	if (svgRep) {
		NSImageRep *svg = [svgRep imageRepWithContentsOfFile:path];
		NSImage *img = [[NSImage alloc] init];
		[img addRepresentation:svg];
		type = XCF_RGB_IMAGE;
		xres = yres = 72;
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];

		SeaLayer *layer = [[SVGLayer alloc] initWithImageRep:imageRep document:doc spp:(type == XCF_RGB_IMAGE) ? 4 : 2];
		if (layer == NULL) {
			return NULL;
		}
		layers = @[layer];
		height = (int)[imageRep pixelsHigh];
		width = (int)[imageRep pixelsWide];

		return self;
	}
	
	
	NSString *importerPath;
	NSImageRep *imageRep;
	id layer;
	NSImage *image;
	BOOL test;
	NSString *path_in, *path_out, *width_arg, *height_arg;
	NSArray *args;
	NSTask *task;
	NSString *tmpSeaImport = @"/tmp/seaimport/";
	
	// Load nib file
	[NSBundle loadNibNamed:@"SVGContent" owner:self];
	
	// Run the scaling panel
	[scalePanel center];
	trueSize = getDocumentSize((char *)[path fileSystemRepresentation]);
	size.width = trueSize.width; size.height = trueSize.height;
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
	[scaleSlider setIntValue:2];
	[NSApp runModalForWindow:scalePanel];
	[scalePanel orderOut:self];
	
	// Add all plug-ins to the array
	importerPath = [[gMainBundle builtInPlugInsPath] stringByAppendingPathComponent:@"SVGImporter.app/Contents/MacOS/SVGImporter"];
	if ([fm fileExistsAtPath:importerPath]) {
		if (![fm fileExistsAtPath:tmpSeaImport])
			[fm createDirectoryAtPath:tmpSeaImport withIntermediateDirectories:YES attributes:@{} error:NULL];
		path_in = path;
		path_out = [[tmpSeaImport stringByAppendingPathComponent:path.lastPathComponent] stringByAppendingPathExtension:@"png"];
		if (size.width > 0 && size.height > 0 && size.width < kMaxImageSize && size.height < kMaxImageSize) {
			width_arg = [NSString stringWithFormat:@"%d", size.width];
			height_arg = [NSString stringWithFormat:@"%d", size.height];
			args = @[path_in, path_out, width_arg, height_arg];
		}
		else {
			args = @[path_in, path_out];
		}
		[waitPanel center];
		[waitPanel makeKeyAndOrderFront:self];
		task = [NSTask launchedTaskWithLaunchPath:importerPath arguments:args];
		[spinner startAnimation:self];
		while ([task isRunning]) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
		[spinner stopAnimation:self];
		[waitPanel orderOut:self];
	}
	else {
		[[SeaController seaWarning] addMessage:LOCALSTR(@"SVG message", @"Seashore is unable to open the given SVG file because the SVG Importer is not installed. The installer for this importer can be found on Seashore's website.") level:kHighImportance];
		return NULL;
	}

	// Open the image
	image = [[NSImage alloc] initByReferencingFile:path_out];
	if (image == NULL) {
		return NULL;
	}
	
	// Form a bitmap representation of the file at the specified path
	imageRep = NULL;
	if ([[image representations] count] > 0) {
		imageRep = [image representations][0];
		if (![imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		}
	}
	if (imageRep == NULL) {
		return NULL;
	}
	
	// Determine the height and width of the image
	height = (int)[imageRep pixelsHigh];
	width = (int)[imageRep pixelsWide];
	
	// Determine the resolution of the image
	xres = yres = 72; 
	
	// Determine the image type
	//test = [[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace];
	test = test || [[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace];
	if (test) 
		type = XCF_GRAY_IMAGE;
	else
		type = XCF_RGB_IMAGE;
		
	// Create the layer
	layer = [[SVGLayer alloc] initWithImageRep:imageRep document:doc spp:(type == XCF_RGB_IMAGE) ? 4 : 2];
	if (layer == NULL) {
		return NULL;
	}
	layers = @[layer];
	
	// Now forget the NSImage
	[fm removeItemAtPath:path_out error:NULL];
	
	return self;
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)update:(id)sender
{
	double factor;
	
	switch ([scaleSlider intValue]) {
		case 0:
			factor = 0.5;
		break;
		case 1:
			factor = 0.75;
		break;
		case 2:
			factor = 1.0;
		break;
		case 3:
			factor = 1.5;
		break;
		case 4:
			factor = 2.0;
		break;
		case 5:
			factor = 3.75;
		break;
		case 6:
			factor = 5.0;
		break;
		case 7:
			factor = 7.5;
		break;
		case 8:
			factor = 10.0;
		break;
		case 9:
			factor = 25.0;
		break;
		case 10:
			factor = 50.0;
		break;
		default:
			factor = 1.0;
		break;
	}
	
	size.width = trueSize.width * factor;
	size.height = trueSize.height * factor;
	
	[sizeLabel setStringValue:[NSString stringWithFormat:@"%d x %d", size.width, size.height]];
}

@end
