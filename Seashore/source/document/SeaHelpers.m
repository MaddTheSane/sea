#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PegasusUtility.h"
#import "SeaWhiteboard.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaSelection.h"
#import "SeaTools.h"
#import "StatusUtility.h"
#import "LayerDataSource.h"
#import "InfoUtility.h"
#import "OptionsUtility.h"

@implementation SeaHelpers

- (void)selectionChanged
{
	[[document docView] setNeedsDisplay:YES]; 
	[[[SeaController utilitiesManager] infoUtilityFor:document] update];
}

- (void)endLineDrawing
{
	id curTool = [[document tools] currentTool];

	// We only need to act if the document is locked
	if ([document locked] && [[document window] attachedSheet] == NULL) {
		
		// Apply the changes
		[(SeaWhiteboard *)[document whiteboard] applyOverlay];
		
		// Notify ourselves of the change
		[self layerContentsChanged:kActiveLayer];
		
		// End line drawing once
		if ([curTool respondsToSelector:@selector(endLineDrawing)])
			[curTool endLineDrawing];		
		
		// End line drawing twice
		[[document docView] endLineDrawing];
		
		// Unlock the document
		[document unlock];
		
	}
	
	// Special case for the effect tool
	if ([[[SeaController utilitiesManager] toolboxUtilityFor:document] tool] == kEffectTool) {
		[curTool reset];
	}
}

- (void)channelChanged
{
	if ([[document contents] spp] != 2)
		[(ToolboxUtility *)[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
	[[document whiteboard] readjustAltData:YES];
	[(StatusUtility *)[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

- (void)resolutionChanged
{
	[[document docView] readjust:YES];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
}

- (void)zoomChanged
{
	[[[SeaController utilitiesManager] optionsUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] updateZoom];
}

- (void)boundariesAndContentChanged:(BOOL)scaling
{
	SeaContent *contents = [document contents];
	int i;
	
	[[document whiteboard] readjust];
	[[document docView] readjust:scaling];
	for (i = 0; i < [contents layerCount]; i++) {
		[[contents layerAtIndex:i] updateThumbnail];
	}
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
	[[document docView] setNeedsDisplay:YES]; 

}

- (void)activeLayerWillChange
{
	[self endLineDrawing];
}

- (void)activeLayerChanged:(int)eventType rect:(IntRect *)rect
{
	SeaWhiteboard *whiteboard = [document whiteboard];
	id docView = [document docView];
	
	[[document selection] readjustSelection];
	if (![[[document contents] activeLayer] hasAlpha] && !document.selection.floating && [[document contents] selectedChannel] == SeaSelectedChannelAlpha) {
		[[document contents] setSelectedChannel:SeaSelectedChannelAll];
		[[document helpers] channelChanged];
	}
	switch (eventType) {
		case kLayerSwitched:
		case kTransparentLayerAdded:
			[whiteboard readjustLayer];
			if ([whiteboard whiteboardIsLayerSpecific]) {
				[whiteboard readjustAltData:YES];
			}
			else if ([[SeaController seaPrefs] layerBounds]) {
				[docView setNeedsDisplay:YES];
			}
		break;
		case kLayerAdded:
		case kLayerDeleted:
			[whiteboard readjustLayer];
			[whiteboard readjustAltData:YES];
		break;
	}
	[[document dataSource] update];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
}

- (void)documentWillFlatten
{
	[self activeLayerWillChange];
}

- (void)documentFlattened
{
	[self activeLayerChanged:kLayerAdded rect:NULL];
}

- (void)typeChanged
{
	[[[SeaController utilitiesManager] toolboxUtilityFor:document] update:NO];
	[[document whiteboard] readjust];
	[self layerContentsChanged:kAllLayers];
	[[[SeaController utilitiesManager] statusUtilityFor:document] update];
	[[[SeaController utilitiesManager] statusUtilityFor:document] updateQuickColor];
}

- (void)applyOverlay
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rect;
	
	rect = [[document whiteboard] applyOverlay];
	layer = [contents activeLayer];
	[layer updateThumbnail];
	[[document whiteboard] update:rect inThread:NO];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)overlayChanged:(IntRect)rect inThread:(BOOL)thread
{
	SeaContent *contents = [document contents];
	
	rect.origin.x += [[contents activeLayer] xoff];
	rect.origin.y += [[contents activeLayer] yoff];
	[[document whiteboard] update:rect inThread:thread];
}

- (void)layerAttributesChanged:(NSInteger)index hold:(BOOL)hold
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rect;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layerAtIndex:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
			[[document whiteboard] update:rect inThread:NO];
		break;
	}
	
	if (!hold)
		[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
}

- (void)layerBoundariesChanged:(NSInteger)index
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layerAtIndex:i] updateThumbnail];
			}
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([contents layerAtIndex:i].linked)
					[[contents layerAtIndex:i] updateThumbnail];
			}
		break;
		default:
			layer = [contents layerAtIndex:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			[layer updateThumbnail];
		break;
	}
	
	[[document selection] readjustSelection];
	[[document whiteboard] readjustLayer];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
	[[document docView] setNeedsDisplay:YES]; 

}

- (void)layerContentsChanged:(NSInteger)index
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layerAtIndex:i] updateThumbnail];
			}
			[[document whiteboard] update];
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([contents layerAtIndex:i].linked)
					[[contents layerAtIndex:i] updateThumbnail];
			}
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layerAtIndex:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [layer width], [layer height]);
			[layer updateThumbnail];
			[[document whiteboard] update:rect inThread:NO];
		break;
	}
	
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)layerOffsetsChanged:(NSInteger)index from:(IntPoint)oldOffsets
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rectA, rectB, rectC;
	int xoff, yoff;

	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
			[[document whiteboard] update];
			layer = [contents activeLayer];
			xoff = [layer xoff];
			yoff = [layer yoff];
		break;
		default:
			layer = [contents layerAtIndex:index];
			xoff = [layer xoff];
			yoff = [layer yoff];
			rectA.origin.x = MIN(xoff, oldOffsets.x);
			rectA.origin.y = MIN(yoff, oldOffsets.y);
			rectA.size.width = MAX(xoff, oldOffsets.x) - MIN(xoff, oldOffsets.x) + [layer width];
			rectA.size.height = MAX(yoff, oldOffsets.y) - MIN(yoff, oldOffsets.y) + [layer height];
			rectB = IntMakeRect(oldOffsets.x, oldOffsets.y, [layer width], [layer height]);
			rectC = IntMakeRect(xoff, yoff, [layer width], [layer height]);
			if (rectA.size.width * rectA.size.height < rectB.size.width * rectB.size.height + rectC.size.width * rectC.size.height) {
				[[document whiteboard] update:rectA inThread:NO];
			}
			else {
				[[document whiteboard] update:rectB inThread:NO];
				[[document whiteboard] update:rectC inThread:NO];
			}
		break;
	}
	
	if (document.selection.active) {
		[[document selection] adjustOffset:IntMakePoint(xoff - oldOffsets.x, yoff - oldOffsets.y)];
	}
}

- (void)layerLevelChanged:(NSInteger)index
{
	SeaContent *contents = [document contents];
	SeaLayer *layer;
	IntRect rect;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
			[[document whiteboard] update];
		break;
		default:
			layer = [contents layerAtIndex:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(SeaLayer *)layer width], [(SeaLayer *)layer height]);
			[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
		break;
	}
	[[document dataSource] update];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateAll];
}

- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect
{
	SeaLayer *layer;
	
	layer = [[document contents] layerAtIndex:index];
	rect.origin.x += [layer xoff];
	rect.origin.y += [layer yoff];
	[(SeaWhiteboard *)[document whiteboard] update:rect inThread:NO];
	[layer updateThumbnail];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)layerTitleChanged
{
	[[document dataSource] update];
	[[[SeaController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

@end
