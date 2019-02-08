//
//  RecentsBarView.m
//  Seashore
//
//  Created by robert engels on 2/4/19.
//

#import "RecentsBarView.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "RecentsUtility.h"
#import "SeaTexture.h"

#define kPreviewWidth 72
#define kPreviewHeight 56
#define kImageSize 48

#define FG_RECT NSRect fg = NSMakeRect(0,0,10,8);
#define BG_RECT NSRect bg = NSMakeRect(8,6,10,8);

@protocol Memory
-(NSString*)memoryAsString;
-(void)drawAt:(NSRect)rect;
-(NSColor*)foreground;
-(NSColor*)background;
-(SeaTexture*)texture;
-(void)restore;
@end

@interface RecentsView : NSView
{
    @public id<Memory> memory;
    @public bool selected;
}
@end
@implementation RecentsView

-(void)drawRect:(NSRect)dirtyRect
{
    [memory drawAt:NSMakeRect(0,4,kImageSize,kImageSize)];

    [[NSColor gridColor] set];
    [NSBezierPath fillRect:NSMakeRect(0,kPreviewHeight-1,kPreviewWidth,1)];
    
    if(selected) {
        [[NSColor selectedControlColor] set];
        [NSBezierPath strokeRect:NSMakeRect(1,1,kPreviewWidth-3,kPreviewHeight-3)];
    }
    
    NSAffineTransform *at = [NSAffineTransform transform];
    [at translateXBy:kImageSize-4 yBy:kPreviewHeight/2+4];
    [at concat];
    
    [self drawColorRect];
    
}
-(BOOL)isFlipped
{
    return YES;
}

- (void)drawColorRect
{
    FG_RECT
    BG_RECT
    
    BOOL foregroundIsTexture = [memory texture]!=NULL;
    
    [self drawColorWell:bg];
    
    // Actual Color
    [[memory background] set];
    [[NSBezierPath bezierPathWithRect:bg] fill];
    
    [self drawColorWell:fg];
    
    if (foregroundIsTexture) {
        [[NSColor colorWithPatternImage:[[memory texture] thumbnail]] set];
        [[NSBezierPath bezierPathWithRect:fg] fill];
    }
    else {
        [[memory foreground] set];
        [[NSBezierPath bezierPathWithRect:fg] fill];
    }
}

- (void)drawColorWell:(NSRect)rect
{
    [[NSColor darkGrayColor] set];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(rect,-2,-2)] fill];
    [[NSColor lightGrayColor] set];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(rect,-1,-1)] fill];
    
    // draw the triangles
    [[NSColor blackColor] set];
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath moveToPoint:rect.origin];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),rect.origin.y)];
    [tempPath lineToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath lineToPoint:rect.origin];
    [tempPath fill];
    // Black
    [[NSColor whiteColor] set];
    tempPath = [NSBezierPath bezierPath];
    [tempPath moveToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),NSMaxY(rect))];
    [tempPath lineToPoint:NSMakePoint(NSMaxX(rect),rect.origin.y)];
    [tempPath lineToPoint:NSMakePoint(rect.origin.x,NSMaxY(rect))];
    [tempPath fill];
}

@end

@interface RecentsItem : NSCollectionViewItem {
    
}
@end
@implementation RecentsItem
- (void)loadView {
    [self setView:[RecentsView new]];
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    if (representedObject==NULL)
        return;
    
    RecentsView *view = (RecentsView*)[self view];
    view->memory = representedObject;
}
- (void)setSelected:(BOOL)selected
{
    RecentsView *view = (RecentsView*)[self view];
    view->selected = selected;
    [view setNeedsDisplay:YES];
    
    if(selected) {
        id<Memory> memory = [self representedObject];
        [memory restore];
    }
    
    [super setSelected:selected];
}
@end

@implementation RecentsBarView 

-(void)awakeFromNib
{
    [cview setItemPrototype:[[RecentsItem alloc] init]];
    [cview setMinItemSize:NSMakeSize(kPreviewWidth,kPreviewHeight)];
    [cview setMaxItemSize:NSMakeSize(kPreviewWidth,kPreviewHeight)];
}

- (void)update
{
    RecentsUtility *util = [[SeaController utilitiesManager] recentsUtilityFor:document];
    int i;
                            
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (i=0; i < [util memoryCount]; i++) {
        [items addObject:[util memoryAt:i]];
    }
    [cview setContent:items];
    [cview setSelectionIndexes:[NSIndexSet new]];
    [cview setFocusRingType:NSFocusRingTypeNone];
}

@end
