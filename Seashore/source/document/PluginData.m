#import "PluginData.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaSelection.h"
#import "SeaWhiteboard.h"
#import "SeaHelpers.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "EffectTool.h"
#import "SeaTools.h"

@implementation PluginData
@synthesize document;

- (IntRect)selection
{
	if (document.selection.active)
		return [document.selection localRect];
	else
		return IntMakeRect(0, 0, [[[document contents] activeLayer] width], [[[document contents] activeLayer] height]);
}

- (unsigned char *)data
{
	return [[[document contents] activeLayer] data];
}

- (unsigned char *)whiteboardData
{
	return [[document whiteboard] data];
}

- (unsigned char *)replace
{
	return [[document whiteboard] replace];
}

- (unsigned char *)overlay
{
	return [[document whiteboard] overlay];
}

- (int)spp
{
	return [[document contents] spp];
}

- (SeaSelectedChannel)channel
{
	if (document.selection.floating)
		return kAllChannels;
	else
		return [[document contents] selectedChannel];	
}

- (int)width
{
	return [[[document contents] activeLayer] width];
}

- (int)height
{
	return [[[document contents] activeLayer] height];
}

- (BOOL)hasAlpha
{
	return [[[document contents] activeLayer] hasAlpha];
}

- (IntPoint)point:(NSInteger)index;
{
	return [[[document tools] getTool:kEffectTool] point:index];
}

- (NSColor *)foreColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] foreground];
}

- (NSColor *)backColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] background];
}

- (CGColorSpaceRef)displayProf
{
	return [[document whiteboard] displayProf];
}

- (id)window
{
	if ([[SeaController seaPrefs] effectsPanel])
		return NULL;
	else
		return [document window];
}

- (SeaOverlayBehaviour)overlayBehaviour
{
	return [[document whiteboard] overlayBehaviour];
}

- (void)setOverlayBehaviour:(SeaOverlayBehaviour)value
{
	[[document whiteboard] setOverlayBehaviour:value];
}

- (int)overlayOpacity
{
	return [[document whiteboard] overlayOpacity];
}

- (void)setOverlayOpacity:(int)value
{
	[[document whiteboard] setOverlayOpacity:value];
}

- (void)applyWithNewDocumentData:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height
{
	NSDocument *newDocument;
	
	if (data == NULL || data == [[document whiteboard] data] || data == [[[document contents] activeLayer] data]) {
		NSAlert *alert = [NSAlert new];
		alert.messageText = NSLocalizedString(@"Critical Plug-in Malfunction", @"Critical Plug-in Malfunction");
		alert.informativeText = NSLocalizedString(@"Plug-in malfunction body", @"The plug-in has returned the same pointer passed to it (or returned NULL). This is a critical malfunction, please refrain from further use of this plug-in and contact the plug-in's developer.");
		
		[alert runModal];
	}
	else {
		newDocument = [[SeaDocument alloc] initWithData:data type:(spp == 4) ? XCF_RGB_IMAGE : XCF_GRAY_IMAGE width:width height:height];
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
	}
}

- (void)apply
{
	[[document helpers] applyOverlay];
}

- (void)preview
{
	[[document helpers] overlayChanged:[self selection] inThread:NO];
}

- (void)cancel
{
	[[document whiteboard] clearOverlay];
	[[document helpers] overlayChanged:[self selection] inThread:NO];
}

@end
