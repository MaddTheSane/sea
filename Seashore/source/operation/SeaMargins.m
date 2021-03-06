#import "SeaMargins.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaHelpers.h"
#import "SeaScale.h"
#import "SeaSelection.h"
#import "Units.h"

@implementation SeaMargins

- (instancetype)init
{
	if (self = [super init]) {
	undoMax = kNumberOfMarginRecordsPerMalloc;
	undoRecords = malloc(undoMax * sizeof(MarginUndoRecord));
	undoCount = 0;
	sheetShown = FALSE;
	}
	
	return self;
}

- (void)dealloc
{
	free(undoRecords);
}

- (void)determineContentBorders
{
	int width, height;
	int spp = [[document contents] spp];
	unsigned char *data;
	int i, j, k;
	id layer;
	
	// Start out with invalid content borders
	contentLeft = contentRight = contentTop = contentBottom =  -1;
	
	// Select the appropriate data for working out the content borders
	if (workingIndex == kAllLayers) {
		data = [(SeaWhiteboard *)[document whiteboard] data];
		width = [(SeaContent *)[document contents] width];
		height = [(SeaContent *)[document contents] height];
	}
	else {
		layer = [[document contents] layerAtIndex:workingIndex];
		data = [(SeaLayer *)layer data];
		width = [(SeaLayer *)layer width];
		height = [(SeaLayer *)layer height];
	}
	
	// Determine left content margin
	for (i = 0; i < width && contentLeft == -1; i++) {
		for (j = 0; j < height && contentLeft == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentLeft = i;
				}
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && contentRight == -1; i--) {
		for (j = 0; j < height && contentRight == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentRight = width - 1 - i;
				}
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && contentTop == -1; j++) {
		for (i = 0; i < width && contentTop == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentTop = j;
				}
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && contentBottom == -1; j--) {
		for (i = 0; i < width && contentBottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						contentBottom = height - 1 - j;
				}
			}
		}
	}
}

- (void)run:(BOOL)global
{
	id contents = [document contents];
	id layer = NULL;
	id menuItem;
	NSString *string;
	float xres, yres;
	
	// Determine the working index
	if (global)
		workingIndex = kAllLayers;
	else
		workingIndex = [[document contents] activeLayerIndex];
		
	// Set the selection label correctly
	if (workingIndex == kAllLayers) {
		[selectionLabel setStringValue:LOCALSTR(@"whole document", @"Whole Document")];
	}
	else {
		layer = [contents layerAtIndex:workingIndex];
		[selectionLabel setStringValue:[layer name]];
		
	}
	
	// Set paper name
	if ([[document printInfo] respondsToSelector:@selector(localizedPaperName)]) {
		menuItem = [presetsMenu itemAtIndex:[presetsMenu indexOfItemWithTag:2]];
		string = [NSString stringWithFormat:@"%@ (%@)", LOCALSTR(@"paper size", @"Paper size"), [[document printInfo] localizedPaperName]];
		[menuItem setTitle:string];
	}

	// Set units
	units = [document measureStyle];
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Set the values properly
	[widthLabel setTitle:SeaUnitsString(units)];
	[heightLabel setTitle:SeaUnitsString(units)];
	[topPopdown selectItemAtIndex:units];
	[bottomLabel setTitle:SeaUnitsString(units)];
	[leftLabel setTitle:SeaUnitsString(units)];
	[rightLabel setTitle:SeaUnitsString(units)];

	[topValue setStringValue:SeaStringFromPixels(0, units, yres)]; [bottomValue setStringValue:SeaStringFromPixels(0, units, yres)];
	[leftValue setStringValue:SeaStringFromPixels(0, units, xres)]; [rightValue setStringValue:SeaStringFromPixels(0, units, xres)];
	if (workingIndex == kAllLayers) {
		[widthValue setStringValue:SeaStringFromPixels([(SeaContent *)contents width], units, xres)];
		[heightValue setStringValue:SeaStringFromPixels([(SeaContent *)contents height],units, yres)];
	}
	else {
		[widthValue setStringValue:SeaStringFromPixels([(SeaLayer *)layer width], units, xres)];
		[heightValue setStringValue:SeaStringFromPixels([(SeaLayer *)layer height], units, yres)];
	}
	
	// Determine the content borders
	[self determineContentBorders];
	
	// If we have invalid content borders don't allow them to be used
	[contentRelative setState:NSOffState];
	if (contentLeft == -1 || contentTop == -1)
		[contentRelative setEnabled:NO];
	else
		[contentRelative setEnabled:YES];
		
	// If we are not playing with the whole document don't let the user apply to all
	if (workingIndex == kAllLayers){
		[clippingMatrix setHidden:NO];
		[sheet setFrame:NSMakeRect([sheet frame].origin.x, [sheet frame].origin.y, [sheet frame].size.width, 376) display: TRUE];
	}else{
		[clippingMatrix setHidden:YES];
		[sheet setFrame:NSMakeRect([sheet frame].origin.x, [sheet frame].origin.y, [sheet frame].size.width, 318) display: TRUE];
	}
	// Make sure the size is correct depending on when we display it
	if(!sheetShown){
		[sheet setFrame:NSMakeRect([sheet frame].origin.x, [sheet frame].origin.y, [sheet frame].size.width, [sheet frame].size.height + 22) display: TRUE];
		sheetShown = TRUE;
	}
	// Update values
	[self marginsChanged:NULL];

	// Show the sheet
	[document.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
		
	}];
}

- (IBAction)apply:(id)sender
{

	float trueLeft, trueRight, trueBottom, trueTop;
	float oldWidth, oldHeight;
	float xres, yres;
	SeaLayer *layer;
	int i;
	
	// End the sheet
	[NSApp stopModal];
	[document.window endSheet:sheet returnCode:NSModalResponseOK];
	[sheet orderOut:self];
	
	// Find the resolution
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Calculate the margin changes in pixels
	trueLeft = SeaPixelsFromFloat([leftValue floatValue], units, xres);
	trueRight = SeaPixelsFromFloat([rightValue floatValue], units, xres);
	trueTop = SeaPixelsFromFloat([topValue floatValue], units, yres);
	trueBottom = SeaPixelsFromFloat([bottomValue floatValue], units, yres);
	
	// Make changes if values are content relative 
	if ([contentRelative state]) {
		trueLeft -= contentLeft; trueRight -= contentRight;
		trueTop -= contentTop; trueBottom -= contentBottom;
	}
	
	// Work out the old width and height
	if (workingIndex == kAllLayers) {
		oldWidth = [(SeaContent *)[document contents] width];
		oldHeight = [(SeaContent *)[document contents] height];
	}
	else {
		oldWidth = [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width];
		oldHeight = [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height];
	}
	
	// Don't continue if values are unreasonable or unchanged
	if (trueLeft + oldWidth + trueRight < kMinImageSize) { NSBeep(); return; }
	if (trueTop + oldHeight + trueBottom < kMinImageSize) { NSBeep(); return; }
	if (trueLeft + oldWidth + trueRight > kMaxImageSize) { NSBeep(); return; }
	if (trueTop + oldHeight + trueBottom > kMaxImageSize) { NSBeep(); return; }
	if (trueLeft == 0 && trueRight == 0 && trueTop == 0 && trueBottom == 0) { return; }
	
	// Make the margin changes
	if (workingIndex == kAllLayers && [clippingMatrix selectedRow] > kNoClipMode) {
		for (i = 0; i < [[document contents] layerCount]; i++) {
			layer = [[document contents] layerAtIndex:i];
			if ([layer width] == oldWidth && [layer height] == oldHeight && [layer xoff] == 0 && [layer yoff] == 0){
				[self setMarginLeft:trueLeft top:trueTop right:trueRight bottom:trueBottom index:i];
			}else if([clippingMatrix selectedRow] == kAllClipMode){
				int newLeft = 0, newRight = 0, newTop = 0, newBottom = 0;
				if([layer xoff] < -1 * trueLeft) newLeft = trueLeft + [layer xoff];
				if([layer yoff] < -1 * trueTop) newTop = trueTop + [layer yoff];
				if([layer xoff] + [layer width] > oldWidth + trueRight) newRight = (int)(oldWidth + trueRight) - ([layer width] + [layer xoff]);
				if([layer yoff] + [layer height] > oldHeight + trueBottom) newBottom = (int)(oldHeight + trueBottom) - ([layer height] + [layer yoff]);
				if((newLeft + newRight + [layer width] < kMinImageSize) || (newTop + newBottom + [layer height] < kMinImageSize)) NSLog(@"Delete Layer?");
				else [self setMarginLeft:newLeft top:newTop right:newRight bottom:newBottom index:i];
			}
		}
	}
	[self setMarginLeft:trueLeft top:trueTop right:trueRight bottom:trueBottom index:workingIndex];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[document.window endSheet:sheet returnCode:NSModalResponseCancel];
	[sheet orderOut:self];
}

- (IBAction)condenseLayer:(id)sender
{
	NSInteger index = [[document contents] activeLayerIndex];
	
	workingIndex = index;
	[self determineContentBorders];
	[self setMarginLeft:-contentLeft top:-contentTop right:-contentRight bottom:-contentBottom index:index];
}

- (IBAction)condenseToSelection:(id)sender
{
	NSInteger index = [[document contents] activeLayerIndex];
	workingIndex = index;

	SeaLayer *activeLayer = [[document contents] activeLayer];
	IntRect selRect = [[document selection] localRect];

	int top = [activeLayer height] - selRect.origin.y - selRect.size.height;
	int right = [activeLayer width] - selRect.origin.x - selRect.size.width;
	
	[self setMarginLeft:-selRect.origin.x top:-selRect.origin.y right:-right bottom:-top index:index];
}

- (IBAction)expandLayer:(id)sender
{
	id layer;
	int width, height;
	
	layer = [[document contents] activeLayer];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	[self setMarginLeft:[layer xoff] top:[layer yoff] right:width - ([layer xoff] + [(SeaLayer *)layer width]) bottom:height - ([layer yoff] + [(SeaLayer *)layer height]) index:kActiveLayer];
}

- (IBAction)cropImage:(id)sender
{
	NSLog(@"Cropping Not Implemented Yet. \n");
}

- (IBAction)maskImage:(id)sender
{
	NSLog(@"Masking Not Implemented Yet. \n");
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(NSInteger)index undoRecord:(MarginUndoRecord *)undoRecord
{
	SeaContent *contents = [document contents];
	SeaLayer *layer = nil;
	NSInteger i;
	
	// Correct the index if necessary
	if (index == kActiveLayer)
		index = [[document contents] activeLayerIndex];
		
	// Get the layer if appropriate
	if (index != kAllLayers)
		layer = [contents layerAtIndex:index];
	
	// Take the snapshots if necessary
	if (undoRecord) {
		undoRecord->left = left;
		undoRecord->top = top;
		undoRecord->right = right;
		undoRecord->bottom = bottom;
		if (index != kAllLayers) {
			for (i = 0; i < 4; i++)
				undoRecord->indicies[i] = -1;
			if (left < 0)
				undoRecord->indicies[0] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, -left, [layer height]) automatic:NO];
			if (top < 0)
				undoRecord->indicies[1] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [layer width],  -top) automatic:NO];
			if (right < 0)
				undoRecord->indicies[2] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect([layer width] + right, 0, -right, [(SeaLayer *)layer height]) automatic:NO];
			if (bottom < 0)
				undoRecord->indicies[3] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, [layer height] + bottom, [(SeaLayer *)layer width], -bottom) automatic:NO];
		}
	}
	
	// Adjust the margins
	if (index == kAllLayers) {
		[[document contents] setMarginLeft:left top:top right:right bottom:bottom];
	}
	else {
		[layer setMarginLeft:left top:top right:right bottom:bottom];
	}
	
	// Update the undo record
	if (undoRecord) {
		undoRecord->index = index;
		undoRecord->isChanged = YES;
	}
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(NSInteger)index
{	
	MarginUndoRecord undoRecord;
	
	// Don't do anything if no changes are needed
	if (left == 0 && top == 0 && right == 0 && bottom == 0)
		return;
	
	// Do the adjustment
	[self setMarginLeft:left top:top right:right bottom:bottom index:index undoRecord:&undoRecord];

	// Allow the undo
	if (undoCount + 1 > undoMax) {
		undoMax += kNumberOfMarginRecordsPerMalloc;
		undoRecords = realloc(undoRecords, undoMax * sizeof(MarginUndoRecord));
	}
	undoRecords[undoCount] = undoRecord;
	[[[document undoManager] prepareWithInvocationTarget:self] undoMargins:undoCount];
	undoCount++;
	
	// Do appropriate updating
	if (index == kAllLayers)
		[[document helpers] boundariesAndContentChanged:NO];
	else
		[[document helpers] layerBoundariesChanged:index];
}

- (void)undoMargins:(NSInteger)undoIndex
{
	MarginUndoRecord undoRecord;
	id layer, contents = [document contents];
	int i;
	
	// Get the undo record
	undoRecord = undoRecords[undoIndex];
	
	// We have different responses depending on whether the change is current or not
	if (undoRecord.isChanged) {
		if (undoRecord.index == kAllLayers) {
			[contents setMarginLeft:-undoRecord.left top:-undoRecord.top right:-undoRecord.right bottom:-undoRecord.bottom];
		} else {
			layer = [contents layerAtIndex:undoRecord.index];
			[layer setMarginLeft:-undoRecord.left top:-undoRecord.top right:-undoRecord.right bottom:-undoRecord.bottom];
			for (i = 0; i < 4; i++) {
				if (undoRecord.indicies[i] != -1) {
					[[layer seaLayerUndo] restoreSnapshot:undoRecord.indicies[i] automatic: NO];
				}
			}
		}
		undoRecord.isChanged = NO;
	} else {
		[self setMarginLeft:undoRecord.left top:undoRecord.top right:undoRecord.right bottom:undoRecord.bottom index:undoRecord.index undoRecord:NULL];
		undoRecord.isChanged = YES;
	}
	
	// Put the updated undo record back and allow the undo
	undoRecords[undoIndex] = undoRecord;
	[[[document undoManager] prepareWithInvocationTarget:self] undoMargins:undoIndex];
	
	// Do appropriate updating
	if (undoRecord.index == kAllLayers)
		[[document helpers] boundariesAndContentChanged:NO];
	else
		[[document helpers] layerBoundariesChanged:undoRecord.index];
}

- (IBAction)marginsChanged:(id)sender
{
	int trueLeft, trueRight, trueBottom, trueTop;
	CGFloat xres, yres;
	int width, height;
	
	// Find the resolution
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Calculate the margin changes in pixels
	trueLeft = SeaPixelsFromFloat([leftValue floatValue], units, xres);
	trueRight = SeaPixelsFromFloat([rightValue floatValue], units, xres);
	trueTop = SeaPixelsFromFloat([topValue floatValue], units, yres);
	trueBottom = SeaPixelsFromFloat([bottomValue floatValue], units, yres);
	
	// Make changes if values are content relative
	if ([contentRelative state]) {
		trueLeft -= contentLeft; trueRight -= contentRight;
		trueTop -= contentTop; trueBottom -= contentBottom;
	}
	
	// Determine the new width and height
	if (workingIndex == kAllLayers) {
		width = [(SeaContent *)[document contents] width] + trueLeft + trueRight;
		height = [(SeaContent *)[document contents] height] + trueTop + trueBottom;
	}
	else {
		width = [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width] + trueLeft + trueRight;
		height = [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height] + trueTop + trueBottom;
	}

	// Finally display the changes
	[widthValue setStringValue:SeaStringFromPixels(width, units, xres)];
	[heightValue setStringValue:SeaStringFromPixels(height, units, yres)];
}

- (IBAction)dimensionsChanged:(id)sender
{
	CGFloat xres, yres;
	int width, height, curLeft, curRight, curTop, curBottom;
	
	// Find the resolution
	xres = [[document contents] xres];
	yres = [[document contents] yres];
	
	// Determine the new width and height
	width = SeaPixelsFromFloat([widthValue floatValue], units, xres);
	height = SeaPixelsFromFloat([heightValue floatValue], units, yres);

	IntSize delta = IntMakeSize(0,0);
	// Work out the margin adjustment needed
	if ([contentRelative state]) {
		if (workingIndex == kAllLayers) {
			delta.width = (width + contentLeft + contentRight) - [(SeaContent *)[document contents] width];
			delta.height = (height + contentTop + contentBottom) - [(SeaContent *)[document contents] height];
		} else {
			delta.width = (width + contentLeft + contentRight) - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width];
			delta.height = (height + contentTop + contentBottom) - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height];
		}
	} else {
		if (workingIndex == kAllLayers) {
			delta.width = width - [(SeaContent *)[document contents] width];
			delta.height = height - [(SeaContent *)[document contents] height];
		} else {
			delta.width = width - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width];
			delta.height = height - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height];
		}
	}
	
	// Calculate how this affects the current margins
	curLeft = SeaPixelsFromFloat([leftValue floatValue], units, xres);
	curRight = SeaPixelsFromFloat([rightValue floatValue], units, xres);
	curTop = SeaPixelsFromFloat([topValue floatValue], units, yres);
	curBottom = SeaPixelsFromFloat([bottomValue floatValue], units, yres);
	delta.width -= (curLeft + curRight);
	delta.height -= (curTop + curBottom);

	// Finally display the changes
	[leftValue setStringValue:SeaStringFromPixels(delta.width / 2 + curLeft, units, xres)];
	[rightValue setStringValue:SeaStringFromPixels(delta.width / 2 + delta.width % 2 + curRight , units, xres)];
	[topValue setStringValue:SeaStringFromPixels(delta.height / 2 + curTop, units, yres)];
	[bottomValue setStringValue:SeaStringFromPixels(delta.height / 2 + delta.height % 2 + curBottom, units, yres)];
}

- (IBAction)unitsChanged:(id)sender
{
	id contents = [document contents];
	CGFloat xres, yres;
	int oldTopValue, oldLeftValue, oldBottomValue, oldRightValue;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Remember the old values
	oldTopValue = SeaPixelsFromFloat([topValue floatValue], units, yres);
	oldBottomValue = SeaPixelsFromFloat([bottomValue floatValue], units, yres);
	oldLeftValue = SeaPixelsFromFloat([leftValue floatValue], units, xres);
	oldRightValue = SeaPixelsFromFloat([rightValue floatValue], units, xres);
				
	// Set units
	units = (SeaUnits)[sender indexOfSelectedItem];
	
	// Set the new labels
	[widthLabel setTitle:SeaUnitsString(units)];
	[heightLabel setTitle:SeaUnitsString(units)];
	[topPopdown selectItemAtIndex:units];
	[bottomLabel setTitle:SeaUnitsString(units)];
	[leftLabel setTitle:SeaUnitsString(units)];
	[rightLabel setTitle:SeaUnitsString(units)];

	// Set the new margins
	[topValue setStringValue:SeaStringFromPixels(oldTopValue, units, yres)];
	[bottomValue setStringValue:SeaStringFromPixels(oldBottomValue, units, yres)];
	[leftValue setStringValue:SeaStringFromPixels(oldLeftValue, units, xres)];
	[rightValue setStringValue:SeaStringFromPixels(oldRightValue, units, xres)];
	
	// Update the rest
	[self marginsChanged:NULL];
}

- (IBAction)changeToPreset:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	CGFloat xres, yres;
	id focusObject;
	SeaContent *contents = [document contents];
	BOOL customOrigin = NO;
	
	// Get the preset's size
	if (workingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layerAtIndex:workingIndex];
	xres = [contents xres];
	yres = [contents yres];
	switch ([[presetsMenu selectedItem] tag]) {
		case 0:
			pboard = [NSPasteboard generalPasteboard];
			availableType = [pboard availableTypeFromArray:@[NSPasteboardTypeTIFF]];
			if (availableType) {
				image = [[NSImage alloc] initWithData:[pboard dataForType:availableType]];
				size = NSSizeMakeIntSize([image size]);
			}
			else {
				NSBeep();
				return;
			}
		break;
		case 1:
			size = NSSizeMakeIntSize([[NSScreen mainScreen] frame].size);
		break;
		case 2:
			paperSize = [[document printInfo] paperSize];
			paperSize.height -= [[document printInfo] topMargin] + [[document printInfo] bottomMargin];
			paperSize.width -= [[document printInfo] leftMargin] + [[document printInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			size.width = (float)size.width * (xres / 72.0);
			size.height = (float)size.height * (yres / 72.0);
		break;
		case 3:
			if(!document.selection.active)
				return;
			size = [[document selection] localRect].size;
			customOrigin = YES;
		break;
		default:
			NSLog(@"Preset not supported.");
		break;
	}
	
	// Work out the margin adjustment needed
	if(customOrigin){
		IntPoint origin;
		if(workingIndex == kAllLayers){
			origin = [[document selection] globalRect].origin;
			[rightValue setStringValue:SeaStringFromPixels( origin.x + size.width - [(SeaContent *)[document contents] width], units, xres)];
			[bottomValue setStringValue:SeaStringFromPixels(origin.y + size.height - [(SeaContent *)[document contents] height] , units, yres)];
		} else {
			origin = [[document selection] localRect].origin;
			[rightValue setStringValue:SeaStringFromPixels(origin.x + size.width - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width] , units, xres)];
			[bottomValue setStringValue:SeaStringFromPixels(origin.y + size.height  - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height], units, yres)];
		}
		[leftValue setStringValue:SeaStringFromPixels(-1 * origin.x, units, xres)];
		[topValue setStringValue:SeaStringFromPixels(-1 * origin.y, units, yres)];
	} else {
		if ([contentRelative state]) {
			if (workingIndex == kAllLayers) {
				size.width = (size.width + contentLeft + contentRight) - [(SeaContent *)[document contents] width];
				size.height = (size.height + contentTop + contentBottom) - [(SeaContent *)[document contents] height];
			} else {
				size.width = (size.width + contentLeft + contentRight) - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width];
				size.height = (size.height + contentTop + contentBottom) - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height];
			}
		} else {
			if (workingIndex == kAllLayers) {
				size.width = size.width - [(SeaContent *)[document contents] width];
				size.height = size.height - [(SeaContent *)[document contents] height];
			} else {
				size.width = size.width - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] width];
				size.height = size.height - [(SeaLayer *)[[document contents] layerAtIndex:workingIndex] height];
			}
		}
		
		// Fill out the panel correctly
		[leftValue setStringValue:SeaStringFromPixels(size.width / 2, units, xres)];
		[rightValue setStringValue:SeaStringFromPixels(size.width / 2 + size.width % 2, units, xres)];
		[topValue setStringValue:SeaStringFromPixels(size.height / 2, units, yres)];
		[bottomValue setStringValue:SeaStringFromPixels(size.height / 2 + size.height % 2, units, yres)];
	}
	
	[self marginsChanged:NULL];
}

@end
