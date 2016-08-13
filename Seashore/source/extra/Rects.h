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
	@discussion	Similar to \c NSPoint except with integer fields.
	@field		x
				The x co-ordinate of the point.
	@field		y
				The y co-ordinate of the point.
*/
typedef struct { int x; int y; } IntPoint;

/*!
	@typedef	IntSize
	@discussion	Similar to \c NSSize except with integer fields.
	@field		width
				The width of the size.
	@field		height
				The height of the size.
*/
typedef struct { int width; int height; } IntSize;

/*!
	@typedef	IntRect
	@discussion	Similar to \c NSRect except with integer fields.
	@field		origin
				An \c IntPoint representing the origin of the rectangle.
	@field		size
				An \c IntSize representing the size of the rectangle.
*/
typedef struct { IntPoint origin; IntSize size; } IntRect;

#endif /* INTRECT_T */

/*!
	@function	NSPointMakeIntPoint
	@discussion	Given an <code>NSPoint</code>, makes an \c IntPoint with similar values (fields
				are rounded down if necessary).
	@param		point
				The \c NSPoint to convert.
	@result		Returns an \c IntPoint with similar values to the <code>NSPoint</code>.
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
	@discussion	Given an <code>NSSize</code>, makes an \c IntSize with similar values (fields are
				rounded up if necessary).
	@param		size
				The \c NSSize to convert.
	@result		Returns an \c IntSize with similar values to the <code>NSSize</code>.
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
	@discussion	Given an <code>IntPoint</code>, makes an \c NSPoint with similar values.
	@param		point
				The \c IntPoint to convert.
	@result		Returns a NSPoint with similar values to the <code>IntPoint</code>.
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
	@discussion	Given a set of integer co-ordinates, makes an <code>IntPoint</code>.
	@param		x
				The x co-ordinate of the new point.
	@param		y
				The y co-ordinate of the new point.
	@result		Returns an \c IntPoint with the given co-ordinates.
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
	@discussion	Given an <code>IntSize</code>, makes an \c NSSize with similar values.
	@param		size
				The \c IntSize to convert.
	@result		Returns a \c NSSize with similar values to the <code>IntSize</code>.
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
	@discussion	Given a set of integer values, makes an <code>IntSize</code>.
	@param		width
				The width of the new size.
	@param		height
				The height of the new size.
	@result		Returns an \c IntSize with the given values.
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
	@discussion	Given a set of integer values, makes an <code>IntRect</code>.
	@param		x
				The x co-ordinate of the origin of the new rectangle.
	@param		y
				The y co-ordinate of the origin of the new rectangle.
	@param		width
				The width of the new rectangle.
	@param		height
				The height of the new rectangle.
	@result		Returns an \c IntRect with the given values.
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
	@discussion	Given a reference to a rectangle, offsets it by the specified
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
	@discussion	Given an <code>IntRect</code>, tests to see if a given \c IntPoint lies within
				it. This function assumes a flipped co-ordinate system like that
				used by QuickDraw or <code>NSPointInRect</code>.
	@param		point
				The point to be tested.
	@param		rect
				The rectangle in which to test for the point.
	@result		\c YES if the point lies within the rectangle, \c NO otherwise.
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
	@discussion	Given an <code>IntRect</code>, tests to see if it entirely contains another
				<code>IntRect</code>.
	@param		bigRect
				The \c IntRect in which the \c littleRect must be contained if
				function is to return <code>YES</code>.
	@param		littleRect
				The \c IntRect with which to test the above condition.
	@result		Returns \c YES if the \c bigRect entirely contains the <code>littleRect</code>, \c NO
				otherwise.
*/
extern BOOL IntContainsRect(IntRect bigRect, IntRect littleRect);

/*!
	@function	IntConstrainRect
	@discussion	Given an <code>IntRect</code>, makes sure it lies within another <code>IntRect</code>.
	@param		littleRect
				The \c IntRect to be constrained to the <code>bigRect</code>.
	@param		bigRect
				The \c IntRect within which the constrained rectangle must lie.
	@result		Returns an \c IntRect that is the \c littleRect constrained to the
				<code>bigRect</code>.
*/
extern IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect);

/*!
	@function	NSConstrainRect
	@discussion	Given an <code>NSRect</code>, makes sure it lies within another <code>NSRect</code>.
	@param		littleRect
				The \c NSRect to be constrained to the <code>bigRect</code>.
	@param		bigRect
				The \c NSRect within which the constrained rectangle must lie.
	@result		Returns an \c NSRect that is the \c littleRect constrained to the
				<code>bigRect</code>.
*/
extern NSRect NSConstrainRect(NSRect littleRect, NSRect bigRect);

/*!
	@function	IntSumRects
	@discussion	Returns an \c IntRect that contains exactly the two input IntRects.
	@param		augendRect
				The first <code>IntRect</code>.
	@param		addendRect
				The second \c IntRect that we are adding to the aguend.
	@result		Returns an \c IntRect that contains the aguend and addend.
*/
extern IntRect IntSumRects(IntRect augendRect, IntRect addendRect);

/*!
	@function	NSRectMakeIntRect
	@discussion	Given an \c NSRect makes an \c IntRect with similar values,  the
				\c IntRect will always exceed the NSRect in size.
	@param		rect
				The \c NSRect to convert.
	@result		Returns an \c IntRect at least the size of NSRect.
*/
extern IntRect NSRectMakeIntRect(NSRect rect);

/*!
	@function	IntRectMakeNSRect
	@discussion	Given an <code>IntRect</code>, makes an \c NSRect with similar values.
	@param		rect
				The \c IntRect to convert.
	@result		Returns an \c NSRect with similar values to the IntRect.
*/
extern NSRect IntRectMakeNSRect(IntRect rect);

/*!
	@function	NSPointRotateNSPoint
	@discussion	Rotates the first \c NSPoint about the second \c NSPoint
	@param		initialPoint
				The point that should be rotated.
	@param		centerPoint
				The point the other point should be rotated about.
	@param		radians
				The number of radians that point is rotated.
	@result		Returns an \c NSPoint with the defined rotation.
*/
extern NSPoint NSPointRotateNSPoint (NSPoint initialPoint, NSPoint centerPoint, CGFloat radians);
