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

#include <CoreFoundation/CFBase.h>
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
  GIMP_INTERPOLATION_NONE CF_SWIFT_NAME(none), 		/**< Specifies no interpolation. */
  GIMP_INTERPOLATION_LINEAR CF_SWIFT_NAME(linear), 	/**< Specifies lower-quality but faster linear interpolation. */
  GIMP_INTERPOLATION_CUBIC CF_SWIFT_NAME(cubic)		/**< Specifies high-quality cubic interpolation */
};

typedef CF_ENUM(int, GimpGradientType) {
  GIMP_GRADIENT_LINEAR CF_SWIFT_NAME(linear),                             /**< Specifies linear gradient */
  GIMP_GRADIENT_BILINEAR CF_SWIFT_NAME(bilinear),                         /**< Specifies bi-linear gradient */
  GIMP_GRADIENT_RADIAL CF_SWIFT_NAME(radial),                             /**< Specifies radial gradient */
  GIMP_GRADIENT_SQUARE CF_SWIFT_NAME(square),                             /**< Specifies square gradient */
  GIMP_GRADIENT_CONICAL_SYMMETRIC CF_SWIFT_NAME(symmetricConical),        /**< Specifies conical (symmetric) gradient */
  GIMP_GRADIENT_CONICAL_ASYMMETRIC CF_SWIFT_NAME(asymmetricConical),      /**< Specifies conical (asymmetric) gradient */
  GIMP_GRADIENT_SHAPEBURST_ANGULAR CF_SWIFT_NAME(angularShapeBurst),      /**< Specifies shapeburst (angular) gradient (NYI)*/
  GIMP_GRADIENT_SHAPEBURST_SPHERICAL CF_SWIFT_NAME(sphericalShapeBurst),  /**< Specifies shapeburst (spherical) gradient (NYI) */
  GIMP_GRADIENT_SHAPEBURST_DIMPLED CF_SWIFT_NAME(dimpledShapeBurst),      /**< Specifies shapeburst (dimpled) gradient (NYI) */
  GIMP_GRADIENT_SPIRAL_CLOCKWISE CF_SWIFT_NAME(clockwiseSpiral),          /**< Specifies spiral (clockwise) gradient */
  GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE CF_SWIFT_NAME(anticlockwiseSpiral)   /**< Specifies spiral (anticlockwise) gradient */
};

typedef CF_ENUM(int, GimpRepeatMode) {
  GIMP_REPEAT_NONE CF_SWIFT_NAME(none),             /**< Specifies no repeat */
  GIMP_REPEAT_SAWTOOTH CF_SWIFT_NAME(sawtooth),     /**< Specifies sawtooth repeat wave */
  GIMP_REPEAT_TRIANGULAR CF_SWIFT_NAME(triangular)  /**< Specifies triangular repeat wave */
};

typedef struct {
	 GimpGradientType gradient_type;	/**< Specifies the gradient type */
	 GimpRepeatMode repeat;				/**< Specifies the repeat mode */
	 unsigned int supersample;			/**< Specifies whether supersampling should be used */
	 int max_depth;						/**< Specifies the maximum depth for use in supersampling */
	 double threshold;					/**< Specifies the threshold for use in supersampling */
	 unsigned char start_color[4];		/**< Specifies the colour to start with */
	 IntPoint start;					/**< Specifies the start co-ordinates */
	 unsigned char end_color[4];		/**< Specifies the colour to end with */
	 IntPoint end;						/**< Specifies the end co-ordinates */
} GimpGradientInfo;

typedef struct _GimpVector2 {
  double x, y;
} GimpVector2;

typedef void (* GimpProgressFunction) (int max, int current);

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
void GCFillGradient(unsigned char *dest, int destWidth, int destHeight, IntRect rect, int spp, GimpGradientInfo info, GimpProgressFunction progress_callback);

/*!
	@function	GCDrawPolygon
	@discussion	Fills the given bitmap with a polygon using the provided points.
 */
void GCDrawPolygon(unsigned char *dest, int destWidth, int destHeight, GimpVector2 *points, int n, int spp);

/*!
	@function	GCRotateImage
	@discussion	Rotates the given bitmap through the specified angle (in radians).
 */
void GCRotateImage(unsigned char **dest, int *destWidth, int *destHeight, int *destX, int *destY, unsigned char *src, int srcWidth, int srcHeight, float angle, GimpInterpolationType interpolation_type, int spp, GimpProgressFunction progress_callback);

#endif /* GIMPCORE_H */
