#import "SVGContent.h"
#import "CocoaLayer.h"
#import "SeaController.h"
#import "SeaDocumentController.h"
#import "SeaWarning.h"
#import <SeashoreKit/SeashoreKit-Swift.h>


@implementation SVGContent

+ (BOOL)typeIsViewable:(NSString *)aType
{
	return [[SeaDocumentController sharedDocumentController] type: aType isContainedInDocType: @"SVG document"];
}

- (instancetype)initWithDocument:(SeaDocument*)doc contentsOfFile:(NSString *)path
{
	if (self = [super initWithDocument:doc]) {
		SVGImporter *svgImp = [[SVGImporter alloc] init];
		SeaLayer *layer = [svgImp loadSVGLayer:doc contentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
		if(layer==NULL)
			return NULL;
			
		// Load nib file
		
		// Determine the height and width of the image
		height = layer.height;
		width = layer.width;
		type = XCF_RGB_IMAGE;
		
		// Determine the resolution of the image
		xres = yres = 72;
		
		// Rename the layer
		[layer setName:path.lastPathComponent.stringByDeletingPathExtension];
		
		layers = [NSArray arrayWithObject:layer];
	}
	return self;
}

@end
