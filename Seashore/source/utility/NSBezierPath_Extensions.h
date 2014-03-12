#import <Cocoa/Cocoa.h>


@interface NSBezierPath(MyExtensions)
+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect andRadius:(CGFloat) radius;
@end

void NSLogRect(NSRect rect);
