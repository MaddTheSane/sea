//
//  GimpBrush.h
//  Brushed
//
//  Created by C.W. Betts on 8/13/16.
//
//

#ifndef GimpBrush_h
#define GimpBrush_h

#include <CoreFoundation/CFBase.h>

typedef struct _BrushHeader {
	unsigned int   header_size;  /**<  header_size = sizeof (BrushHeader) + brush name  */
	unsigned int   version;      /**<  brush file version #  */
	unsigned int   width;        /**<  width of brush  */
	unsigned int   height;       /**<  height of brush  */
	unsigned int   bytes;        /**<  depth of brush in bytes */
	unsigned int   magic_number; /**<  GIMP brush magic number  */
	unsigned int   spacing;      /**<  brush spacing  */
} BrushHeader;

CF_ENUM(OSType) {
	GBRUSH_MAGIC = (('G' << 24) + ('I' << 16) + ('M' << 8) + ('P' << 0))
};
#if 0 // because Xcode is a dumb-dumb.
}
#endif

#endif /* GimpBrush_h */
