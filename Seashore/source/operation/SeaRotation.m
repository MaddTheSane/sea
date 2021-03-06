#import "PositionTool.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaSelection.h"
#import "SeaLayerUndo.h"
#import "SeaRotation.h"

@implementation SeaRotation

- (instancetype)init
{
	if (self = [super init]) {
		undoMax = kNumberOfRotationRecordsPerMalloc;
		undoRecords = malloc(undoMax * sizeof(RotationUndoRecord));
		undoCount = 0;
	}
	
	return self;
}

- (void)dealloc
{
	free(undoRecords);
}

- (void)run
{
	SeaContent *contents = [document contents];
	SeaLayer *layer = NULL;

	// Fill out the selection label
	layer = [contents layerAtIndex:[contents activeLayerIndex]];
	if (layer.floating)
		[selectionLabel setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
	else
		[selectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	
	// Set the initial values
	[rotateValue setStringValue:@"0"];

	// Show the sheet
	[document.window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
		
	}];
}

- (IBAction)apply:(id)sender
{
	SeaContent *contents = [document contents];
	
	// End the sheet
	[NSApp stopModal];
	[document.window endSheet:sheet returnCode:NSModalResponseOK];
	[sheet orderOut:self];

	// Rotate the image
	if ([rotateValue floatValue] != 0) {
		SeaLayer *layer = [contents layerAtIndex:[contents activeLayerIndex]];
		[self rotate:[rotateValue floatValue] withTrim:layer.floating];
	}
}

- (IBAction)cancel:(id)sender
{
	// End the sheet
	[NSApp stopModal];
	[document.window endSheet:sheet returnCode:NSModalResponseCancel];
	[sheet orderOut:self];
}

static inline CGFloat mod_float(CGFloat value, CGFloat divisor)
{
	CGFloat result;
	
	if (value < 0.0) {
		result = value * -1.0;
	} else {
		result = value;
	}

	while (result - 360.0 >= 0.0) {
		result -= 360.0;
	}
	
	return result;
}

- (void)rotate:(CGFloat)degrees withTrim:(BOOL)trim
{
	SeaContent *contents = [document contents];
	SeaLayer *activeLayer = [contents activeLayer];
	RotationUndoRecord undoRecord;
	
	// Only rotate
	if (degrees > 0)
		degrees = 360 - mod_float(degrees, 360);
	else
		degrees = mod_float(degrees, 360);
	if (degrees == 0.0)
		return;

	// Record the undo details
	undoRecord.index =  [contents activeLayerIndex];
	undoRecord.rotation = degrees;
	undoRecord.undoIndex = [[activeLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [activeLayer width], [activeLayer height]) automatic:NO];
	undoRecord.rect = IntMakeRect([activeLayer xoff], [activeLayer yoff], [activeLayer width], [activeLayer height]);
	undoRecord.isRotated = YES;
	undoRecord.withTrim = trim;
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoCount];
	[activeLayer setRotation:degrees interpolation:NSImageInterpolationHigh withTrim:trim];
	if (activeLayer.floating && trim) [[document selection] selectOpaque];
	else [[document selection] clearSelection];
	if (!trim && ![activeLayer hasAlpha]) {
		undoRecord.disableAlpha = YES;
		[activeLayer toggleAlpha];
	}
	else {
		undoRecord.disableAlpha = NO;
	}
	[[document helpers] layerBoundariesChanged:kActiveLayer];

	// Allow the undo
	if (undoCount + 1 > undoMax) {
		undoMax += kNumberOfRotationRecordsPerMalloc;
		undoRecords = realloc(undoRecords, undoMax * sizeof(RotationUndoRecord));
	}
	undoRecords[undoCount] = undoRecord;
	undoCount++;
}

- (void)undoRotation:(NSInteger)undoIndex
{
	SeaContent *contents = [document contents];
	RotationUndoRecord undoRecord;
	SeaLayer *layer;
	
	// Prepare for redo
	[[[document undoManager] prepareWithInvocationTarget:self] undoRotation:undoIndex];
	
	// Get the undo record
	undoRecord = undoRecords[undoIndex];
	
	// Behave differently depending on whether things are already rotated
	if (undoRecord.isRotated) {
		// If already rotated...
		layer = [contents layerAtIndex:undoRecord.index];
		[layer setOffsets:IntMakePoint(undoRecord.rect.origin.x, undoRecord.rect.origin.y)];
		[layer setMarginLeft:0 top:0 right:undoRecord.rect.size.width - [layer width] bottom:undoRecord.rect.size.height - [layer height]];
		[[layer seaLayerUndo] restoreSnapshot:undoRecord.undoIndex automatic:NO];
		if (undoRecord.withTrim)
			[[document selection] selectOpaque];
		else
			[[document selection] clearSelection];
		if (undoRecord.disableAlpha)
			[layer toggleAlpha];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
		undoRecords[undoIndex].isRotated = NO;
	} else {
		// If not rotated...
		layer = [contents layerAtIndex:undoRecord.index];
		[layer setRotation:undoRecord.rotation interpolation:NSImageInterpolationHigh withTrim:undoRecord.withTrim];
		if (undoRecord.withTrim)
			[[document selection] selectOpaque];
		else
			[[document selection] clearSelection];
		[[document helpers] layerBoundariesChanged:kActiveLayer];
		undoRecords[undoIndex].isRotated = YES;
	}
}


@end
