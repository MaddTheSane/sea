/*
	GIMPCore -- a framework featuring various useful functions of the GIMP
	Copyright (c) 1995 Spencer Kimball and Peter Mattis
	Copyright (c) 2003 Mark Pazolli
	Copyright (c) 2004 Andreas Schiffler
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef GIMPCORE_H
#define GIMPCORE_H

#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <stdlib.h>

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
typedef struct {
  /*! The x co-ordinate of the point. */
  int x;
  /*! The y co-ordinate of the point. */
  int y;
} IntPoint;

/*!
	@typedef	IntSize
	@discussion	Similar to \c NSSize except with integer fields.
	@field		width
				The width of the size.
	@field		height
				The height of the size.
 */
typedef struct {
  /*! The width of the size. */
  int width;
  /*! The height of the size. */
  int height;
} IntSize;

/*!
	@typedef	IntRect
	@discussion	Similar to \c NSRect except with integer fields.
	@field		origin
				An IntPoint representing the origin of the rectangle.
	@field		size
				An IntSize representing the size of the rectangle.
 */
typedef struct {
  /*! An \c IntPoint representing the origin of the rectangle. */
  IntPoint origin;
  /*! An \c IntSize representing the size of the rectangle. */
  IntSize size;
} IntRect;
#endif /* INTRECT_T */

typedef CF_ENUM(int, GimpInterpolationType) {
  /*! Specifies no interpolation. */
  GIMP_INTERPOLATION_NONE,
  /*! Specifies lower-quality but faster linear interpolation. */
  GIMP_INTERPOLATION_LINEAR,
  /*! Specifies high-quality cubic interpolation */
  GIMP_INTERPOLATION_CUBIC
};

typedef CF_ENUM(int, GimpGradientType) {
  /*! Specifies linear gradient */
  GIMP_GRADIENT_LINEAR,
  /*! Specifies bi-linear gradient */
  GIMP_GRADIENT_BILINEAR,
  /*! Specifies radial gradient */
  GIMP_GRADIENT_RADIAL,
  /*! Specifies square gradient */
  GIMP_GRADIENT_SQUARE,
  /*! Specifies conical (symmetric) gradient */
  GIMP_GRADIENT_CONICAL_SYMMETRIC,
  /*! Specifies conical (asymmetric) gradient */
  GIMP_GRADIENT_CONICAL_ASYMMETRIC,
  /*! Specifies shapeburst (angular) gradient (NYI)*/
  GIMP_GRADIENT_SHAPEBURST_ANGULAR,
  /*! Specifies shapeburst (spherical) gradient (NYI) */
  GIMP_GRADIENT_SHAPEBURST_SPHERICAL,
  /*! Specifies shapeburst (dimpled) gradient (NYI) */
  GIMP_GRADIENT_SHAPEBURST_DIMPLED,
  /*! Specifies spiral (clockwise) gradient */
  GIMP_GRADIENT_SPIRAL_CLOCKWISE,
  /*! Specifies spiral (anticlockwise) gradient */
  GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE
};

typedef CF_ENUM(int, GimpRepeatMode) {
  /*! Specifies no repeat */
  GIMP_REPEAT_NONE,
  /*! Specifies sawtooth repeat wave */
  GIMP_REPEAT_SAWTOOTH,
  /*! Specifies triangular repeat wave */
  GIMP_REPEAT_TRIANGULAR
};

typedef struct {
  /*! Specifies the gradient type */
  GimpGradientType gradient_type;
  /*! Specifies the repeat mode */
  GimpRepeatMode repeat;
  /*! Specifies whether supersampling should be used */
  unsigned int supersample;
  /*! Specifies the maximum depth for use in supersampling */
  int max_depth;
  /*! Specifies the threshold for use in supersampling */
  double threshold;
  /*! Specifies the colour to start with */
  unsigned char start_color[4];
  /*! Specifies the start co-ordinates */
  IntPoint start;
  /*! Specifies the colour to end with */
  unsigned char end_color[4];
  /*! Specifies the end co-ordinates */
  IntPoint end;
} GimpGradientInfo;

typedef struct _GimpVector2 GimpVector2;

struct _GimpVector2
{
  double x, y;
};

typedef void (* ProgressFunction) (int max, int current);

/*!
	@function	GCScalePixels
	@discussion	Scales the pixels of the source bitmap so that they fill the destination
				bitmap using the specified interpolation style (see GCConstants).
 */
void GCScalePixels(unsigned char *dest, int destWidth, int destHeight, unsigned char *src, int srcWidth, int srcHeight, GimpInterpolationType interpolation, int spp);

/*!
	@function	GCDrawEllipse
	@discussion	Fills the given bitmap with an ellipse of the specified dimensions.
 */
void GCDrawEllipse(unsigned char *dest, int destWidth, int destHeight, IntRect rect, unsigned int antialiased);

/*!
	@function	GCFillGradient
	@discussion	Fills a rectangle of the given bitmap with the given gradient.
 */
void GCFillGradient(unsigned char *dest, int destWidth, int destHeight, IntRect rect, int spp, GimpGradientInfo info, ProgressFunction progress_callback);

/*!
	@function	GCDrawPolygon
	@discussion	Fills the given bitmap with a polygon using the provided points.
 */
void GCDrawPolygon(unsigned char *dest, int destWidth, int destHeight, GimpVector2 *points, int n, int spp);

/*!
	@function	GCRotateImage
	@discussion	Rotates the given bitmap through the specified angle (in radians).
 */
void GCRotateImage(unsigned char **dest, int *destWidth, int *destHeight, int *destX, int *destY, unsigned char *src, int srcWidth, int srcHeight, float angle, GimpInterpolationType interpolation_type, int spp, ProgressFunction progress_callback);

#endif /* GIMPCORE_H */
