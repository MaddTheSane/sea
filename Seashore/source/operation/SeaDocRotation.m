#import "SeaDocument.h"
#import "SeaLayerUndo.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaDocRotation.h"

@implementation SeaDocRotation

- (void)flipDocHorizontally
{
	NSInteger i, layerCount;
	
	[[[document undoManager] prepareWithInvocationTarget:self] flipDocHorizontally];
	[[document selection] clearSelection];
	layerCount = [[document contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[document contents] layer:i] flipHorizontally];
	}
	[[document helpers] boundariesAndContentChanged:NO];
}

- (void)flipDocVertically
{
	NSInteger i, layerCount;
	
	[[[document undoManager] prepareWithInvocationTarget:self] flipDocVertically];
	[[document selection] clearSelection];
	layerCount = [[document contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[document contents] layer:i] flipVertically];
	}
	[[document helpers] boundariesAndContentChanged:NO];
}

- (void)rotateDocLeft
{
	NSInteger i, layerCount;
	int width, height;
	
	[[[document undoManager] prepareWithInvocationTarget:self] rotateDocRight];
	[[document selection] clearSelection];
	layerCount = [[document contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[document contents] layer:i] rotateLeft];
	}
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	[[document contents] setWidth:height height:width];
	[[document helpers] boundariesAndContentChanged:NO];
}

- (void)rotateDocRight
{
	NSInteger i, layerCount;
	int width, height;
	
	[[[document undoManager] prepareWithInvocationTarget:self] rotateDocLeft];
	[[document selection] clearSelection];
	layerCount = [[document contents] layerCount];
	for (i = 0; i < layerCount; i++) {
		[[[document contents] layer:i] rotateRight];
	}
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	[[document contents] setWidth:height height:width];
	[[document helpers] boundariesAndContentChanged:NO];
}

@end
