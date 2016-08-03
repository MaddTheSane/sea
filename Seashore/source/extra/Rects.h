/*!
	@header		Rects
	@abstract	Adds support for integer versions of NSRect, NSSize,  and
				NSPoint (called IntRect, IntSize and IntPoint).
	@discussion	Often in Seashore it is necessary to speak about a particular
				point, size or rectangle that can only have integer values.
				Rather than mess around with floating point conversions, this
				header provides a number of functions to effectively work with
				such points, sizes or rectangles directly. It is included in the
				global header and so all project files should have access to
				these functions.
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#ifndef SEASYSPLUGIN
#include <GIMPCore/GIMPCore.h>
#endif

#ifndef INTRECT_T
#define INTRECT_T

/*!
	@typedef	IntPoint
	@discussion	Similar to NSPoint except with integer fields.
	@field		x
				The x co-ordinate of the point.
	@field		y
				The y co-ordinate of the point.
*/
typedef struct { int x; int y; } IntPoint;

/*!
	@typedef	IntSize
	@discussion	Similar to NSSize except with integer fields.
	@field		width
				The width of the size.
	@field		height
				The height of the size.
*/
typedef struct { int width; int height; } IntSize;

/*!
	@typedef	IntRect
	@discussion	Similar to NSRect except with integer fields.
	@field		origin
				An IntPoint representing the origin of the rectangle.
	@field		size
				An IntSize representing the size of the rectangle.
*/
typedef struct { IntPoint origin; IntSize size; } IntRect;

#endif /* INTRECT_T */

/*!
	@function	NSPointMakeIntPoint
	@discussion	Given an NSPoint makes an IntPoint with similar values fields
				are rounded down if necessary).
	@param		point
				The NSPoint to convert.
	@result		Returns an IntPoint with similar values to the NSPoint.
*/
static inline IntPoint NSPointMakeIntPoint(NSPoint point)
{
	IntPoint newPoint;
	
#if defined(CGFLOAT_IS_DOUBLE) && CGFLOAT_IS_DOUBLE == 1
	newPoint.x = floor(point.x);
	newPoint.y = floor(point.y);
#else
	newPoint.x = floorf(point.x);
	newPoint.y = floorf(point.y);
#endif
	
	return newPoint;
}

/*!
	@function	NSSizeMakeIntSize
	@discussion	Given an NSSize makes an IntSize with similar values fields are
				rounded up if necessary).
	@param		size
				The NSSize to convert.
	@result		Returns an IntSize with similar values to the NSSize.
*/
static inline IntSize NSSizeMakeIntSize(NSSize size)
{
	IntSize newSize;
	
#if defined(CGFLOAT_IS_DOUBLE) && CGFLOAT_IS_DOUBLE == 1
	newSize.width = ceil(size.width);
	newSize.height = ceil(size.height);
#else
	newSize.width = ceilf(size.width);
	newSize.height = ceilf(size.height);
#endif
	
	return newSize;
}

/*!
	@function	IntPointMakeNSPoint
	@discussion	Given an IntPoint makes an NSPoint with similar values.
	@param		point
				The IntPoint to convert.
	@result		Returns a NSPoint with similar values to the IntPoint.
*/
static inline NSPoint IntPointMakeNSPoint(IntPoint point)
{
	NSPoint newPoint;
	
	newPoint.x = point.x;
	newPoint.y = point.y;
	
	return newPoint;
}

/*!
	@function	IntMakePoint
	@discussion	Given a set of integer co-ordinates makes an IntPoint.
	@param		x
				The x co-ordinate of the new point.
	@param		y
				The y co-ordinate of the new point.
	@result		Returns an IntPoint with the given co-ordinates.
*/
static inline IntPoint IntMakePoint(int x, int y)
{
	IntPoint newPoint;
	
	newPoint.x = x;
	newPoint.y = y;
	
	return newPoint;
}

/*!
	@function	IntSizeMakeNSSize
	@discussion	Given an IntSize makes an NSSize with similar values.
	@param		size
				The IntSize to convert.
	@result		Returns a NSSize with similar values to the IntSize.
*/
static inline NSSize IntSizeMakeNSSize(IntSize size)
{
	NSSize newSize;
	
	newSize.width = size.width;
	newSize.height = size.height;
	
	return newSize;
}

/*!
	@function	IntMakeSize
	@discussion	Given a set of integer values makes an IntSize.
	@param		width
				The width of the new size.
	@param		height
				The height of the new size.
	@result		Returns an IntSize with the given values.
*/
static inline IntSize IntMakeSize(int width, int height)
{
	IntSize newSize;
	
	newSize.width = width;
	newSize.height = height;
	
	return newSize;
}

/*!
	@function	IntMakeRect
	@discussion	Given a set of integer values makes an IntRect.
	@param		x
				The x co-ordinate of the origin of the new rectangle.
	@param		y
				The y co-ordinate of the origin of the new rectangle.
	@param		width
				The width of the new rectangle.
	@param		height
				The height of the new rectangle.
	@result		Returns an IntRect with the given values.
*/
static inline IntRect IntMakeRect(int x, int y, int width, int height)
{
	IntRect newRect;
	
	newRect.origin.x = x;
	newRect.origin.y = y;
	newRect.size.width = width;
	newRect.size.height = height;
	
	return newRect;
}

/*!
	@function	IntOffsetRect
	@discussion	Given a reference to a rectangle offsets it by the specified
				co-ordinates.
	@param		rect
				A reference to the rectangle to be offset.
	@param		x
				The amount by which to offset the x co-ordinates.
	@param		y
				The amount by which to offset the y co-ordinates.
*/
static inline void IntOffsetRect(IntRect *rect, int x, int y)
{
	rect->origin.x += x;
	rect->origin.y += y;
}

/*!
	@function	IntPointInRect
	@discussion	Given an IntRect tests to see if a given IntPoint lies within
				it. This function assumes a flipped co-ordinate system like that
				used by QuickDraw or NSPointInRect.
	@param		point
				The point to be tested.
	@param		rect
				The rectangle in which to test for the point.
	@result		YES if the point lies within the rectangle, NO otherwise.
*/
static inline BOOL IntPointInRect(IntPoint point, IntRect rect)
{
	if (point.x < rect.origin.x) return NO;
	if (point.x >= rect.origin.x + rect.size.width) return NO;
	if (point.y < rect.origin.y) return NO;
	if (point.y >= rect.origin.y + rect.size.height) return NO;
	
	return YES;
}

/*!
	@function	IntContainsRect
	@discussion	Given an IntRect tests to see if it entirely contains another
				IntRect.
	@param		bigRect
				The IntRect in which the littleRect must be contained if
				function is to return YES.
	@param		littleRect
				The IntRect with which to test the above condition.
	@result		Returns YES if the bigRect entirely contains the littleRect, NO
				otherwise.
*/
extern BOOL IntContainsRect(IntRect bigRect, IntRect littleRect);

/*!
	@function	IntConstrainRect
	@discussion	Given an IntRect makes sure it lies within another IntRect.
	@param		littleRect
				The IntRect to be constrained to the bigRect.
	@param		bigRect
				The IntRect within which the constrained rectangle must lie.
	@result		Returns an IntRect that is the littleRect constrained to the
				bigRect.
*/
extern IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect);

/*!
	@function	NSConstrainRect
	@discussion	Given an NSRect makes sure it lies within another NSRect.
	@param		littleRect
				The NSRect to be constrained to the bigRect.
	@param		bigRect
				The NSRect within which the constrained rectangle must lie.
	@result		Returns an NSRect that is the littleRect constrained to the
				bigRect.
*/
extern NSRect NSConstrainRect(NSRect littleRect, NSRect bigRect);

/*!
	@function	IntSumRects
	@discussion	Returns an IntRect that contains exactly the two input IntRects.
	@param		augendRect
				The first IntRect.
	@param		addendRect
				The second IntRect that we are adding to the aguend.
	@result		Returns an IntRect that contains the aguend and addend.
*/
extern IntRect IntSumRects(IntRect augendRect, IntRect addendRect);

/*!
	@function	NSRectMakeIntRect
	@discussion	Given an NSRect makes an IntRect with similar values,  the
				IntRect will always exceed the NSRect in size.
	@param		rect
				The NSRect to convert.
	@result		Returns an IntRect at least the size of NSRect.
*/
extern IntRect NSRectMakeIntRect(NSRect rect);

/*!
	@function	IntRectMakeNSRect
	@discussion	Given an \c IntRect makes an \c NSRect with similar values.
	@param		rect
				The I\c ntRect to convert.
	@result		Returns an \c NSRect with similar values to the IntRect.
*/
extern NSRect IntRectMakeNSRect(IntRect rect);

/*!
	@function	NSPointRotateNSPoint
	@discussion	Rotates the first NSPoint about the second NSPoint
	@param		initialPoint
				The point that should be rotated.
	@param		centerPoint
				The point the other point should be rotated about.
	@param		radians
				The number of radians that point is rotated.
	@result		Returns an NSPoint with the defined rotation.
*/
extern NSPoint NSPointRotateNSPoint (NSPoint initialPoint, NSPoint centerPoint, CGFloat radians);
