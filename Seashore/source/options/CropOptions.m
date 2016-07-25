#import "CropOptions.h"
#import "SeaController.h"
#import "SeaHelp.h"
#import "SeaDocument.h"
#import "SeaTools.h"
#import "CropTool.h"
#import "SeaMargins.h"
#import "SeaOperations.h"
#import "SeaContent.h"
#import "AspectRatio.h"

#define customItemIndex 2

@implementation CropOptions

- (void)awakeFromNib
{	
	[aspectRatio awakeWithMaster:self andString:@"crop"];
}

- (NSSize)ratio
{
	return [aspectRatio ratio];
}

- (SeaAspectType)aspectType
{
	return [aspectRatio aspectType];
}

- (IBAction)crop:(id)sender
{
	IntRect cropRect = [[[gCurrentDocument tools] currentTool] cropRect];
	if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
	if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
	int width = [(SeaContent *)[(SeaDocument*)gCurrentDocument contents] width];
	int height = [(SeaContent *)[(SeaDocument*)gCurrentDocument contents] height];
	[[[(SeaDocument*)gCurrentDocument operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:kAllLayers];
	[[[gCurrentDocument tools] currentTool] clearCrop];
}

- (void)shutdown
{
	[aspectRatio shutdown];
}

@end
