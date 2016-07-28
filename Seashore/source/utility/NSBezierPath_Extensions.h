#import <Cocoa/Cocoa.h>


@interface NSBezierPath(MyExtensions)
+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect andRadius:(CGFloat) radius;
@end

extern void NSLogRect(NSRect rect);
