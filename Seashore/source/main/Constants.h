/*!
	@header		Constants
	@abstract	Defines various constants use by Seashore and the XCF file
				format.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, XcfPropType) {
	PROP_END                   =  0,
	PROP_COLORMAP              =  1,
	PROP_ACTIVE_LAYER          =  2,
	PROP_ACTIVE_CHANNEL        =  3,
	PROP_SELECTION             =  4,
	PROP_FLOATING_SELECTION    =  5,
	PROP_OPACITY               =  6,
	PROP_MODE                  =  7,
	PROP_VISIBLE               =  8,
	PROP_LINKED                =  9,
	PROP_PRESERVE_TRANSPARENCY = 10,
	PROP_APPLY_MASK            = 11,
	PROP_EDIT_MASK             = 12,
	PROP_SHOW_MASK             = 13,
	PROP_SHOW_MASKED           = 14,
	PROP_OFFSETS               = 15,
	PROP_COLOR                 = 16,
	PROP_COMPRESSION           = 17,
	PROP_GUIDES                = 18,
	PROP_RESOLUTION            = 19,
	PROP_TATTOO                = 20,
	PROP_PARASITES             = 21,
	PROP_UNIT                  = 22,
	PROP_PATHS                 = 23,
	PROP_USER_UNIT             = 24
};

/*!
	@enum		XcfCompressionType
	@constant	COMPRESS_NONE
				Indicates no compression is used.
	@constant	COMPRESS_RLE
				Indicates compression through run-length encoding is used.
*/
typedef NS_ENUM(int, XcfCompressionType) {
	//! Indicates no compression is used.
	COMPRESS_NONE NS_SWIFT_NAME(none)		=  0,
	//! Indicates compression through run-length encoding is used.
	COMPRESS_RLE NS_SWIFT_NAME(RLE)			=  1,
	COMPRESS_ZLIB NS_SWIFT_NAME(zLib)		=  2,  /**< unused */
	COMPRESS_FRACTAL NS_SWIFT_NAME(fractal)	=  3   /**< unused */
};


/*!
	@enum		XcfLayerMode
	@constant	XCF_NORMAL_MODE
				The normal merge technique.
	@constant	XCF_DISSOLVE_MODE
				The dissolve merge technique.
	@constant	XCF_MULTIPLY_MODE
				The multiply merge technique.
	@constant	XCF_SCREEN_MODE
				The screen merge technique.
	@constant	XCF_OVERLAY_MODE
				The overlay merge technique.
	@constant	XCF_DIFFERENCE_MODE
				The difference merge technique.
	@constant	XCF_ADDITION_MODE
				The addition merge technique.
	@constant	XCF_SUBTRACT_MODE
				The subtract merge technique.
	@constant	XCF_DARKEN_ONLY_MODE
				The darken-only merge technique.
	@constant	XCF_LIGHTEN_ONLY_MODE
				The lighten-only merge technique.
	@constant	XCF_HUE_MODE
				The hue-mode merge technique.
	@constant	XCF_SATURATION_MODE
				The saturation-mode merge technique.
	@constant	XCF_COLOR_MODE
				The colour-mode merge technique.
	@constant	XCF_VALUE_MODE
				The value-mode merge technique.
	@constant	XCF_DIVIDE_MODE
				The divide merge technique.
	@constant	XCF_DODGE_MODE
				The dodge merge technique.
	@constant	XCF_BURN_MODE
				The brun merge technique.
	@constant	XCF_HARDLIGHT_MODE
				The hard light merge technique.
	@constant	XCF_SOFTLIGHT_MODE
				The soft light merge technique.
	@constant	XCF_GRAIN_EXTRACT_MODE
				The grain extract merge technique.
	@constant	XCF_GRAIN_MERGE_MODE
				The grain merge merge technique.
*/	
typedef NS_ENUM(int, XcfLayerMode) {
	//! The normal merge technique.
	XCF_NORMAL_MODE NS_SWIFT_NAME(normal),				/* 0 */
	//! The dissolve merge technique.
	XCF_DISSOLVE_MODE NS_SWIFT_NAME(dissolve),			/* 1 */
	XCF_BEHIND_MODE NS_SWIFT_NAME(behind),				/* 2 */
	//! The multiply merge technique.
	XCF_MULTIPLY_MODE NS_SWIFT_NAME(multiply),			/* 3 */
	//! The screen merge technique.
	XCF_SCREEN_MODE NS_SWIFT_NAME(screen),				/* 4 */
	//! The overlay merge technique.
	XCF_OVERLAY_MODE NS_SWIFT_NAME(overlay),			/* 5 */
	//! The difference merge technique.
	XCF_DIFFERENCE_MODE NS_SWIFT_NAME(difference),		/* 6 */
	//! The addition merge technique.
	XCF_ADDITION_MODE NS_SWIFT_NAME(addition),			/* 7 */
	//! The subtract merge technique.
	XCF_SUBTRACT_MODE NS_SWIFT_NAME(subtract),			/* 8 */
	//! The darken-only merge technique.
	XCF_DARKEN_ONLY_MODE NS_SWIFT_NAME(darkenOnly),		/* 9 */
	//! The lighten-only merge technique.
	XCF_LIGHTEN_ONLY_MODE NS_SWIFT_NAME(lightenOnly),	/* 10 */
	//! The hue-mode merge technique.
	XCF_HUE_MODE NS_SWIFT_NAME(hue),					/* 11 */
	//! The saturation-mode merge technique.
	XCF_SATURATION_MODE NS_SWIFT_NAME(saturation),		/* 12 */
	//! The colour-mode merge technique.
	XCF_COLOR_MODE NS_SWIFT_NAME(color),				/* 13 */
	//! The value-mode merge technique.
	XCF_VALUE_MODE NS_SWIFT_NAME(value),				/* 14 */
	//! The divide merge technique.
	XCF_DIVIDE_MODE NS_SWIFT_NAME(divide),				/* 15 */
	//! The dodge merge technique.
	XCF_DODGE_MODE NS_SWIFT_NAME(dodge),				/* 16 */
	//! The brun merge technique.
	XCF_BURN_MODE NS_SWIFT_NAME(burn),					/* 17 */
	//! The hard light merge technique.
	XCF_HARDLIGHT_MODE NS_SWIFT_NAME(hardLight),		/* 18 */
	//! The soft light merge technique.
	XCF_SOFTLIGHT_MODE NS_SWIFT_NAME(softLight),		/* 19 */
	//! The grain extract merge technique.
	XCF_GRAIN_EXTRACT_MODE NS_SWIFT_NAME(grainExtract), /* 20 */
	//! The grain merge merge technique.
	XCF_GRAIN_MERGE_MODE NS_SWIFT_NAME(grainMerge),		/* 21 */
	XCF_COLOR_ERASE_MODE NS_SWIFT_NAME(colorErase),
	XCF_ERASE_MODE NS_SWIFT_NAME(erase),				/**< skip */
	XCF_REPLACE_MODE NS_SWIFT_NAME(replace),			/**< skip */
	XCF_ANTI_ERASE_MODE NS_SWIFT_NAME(antiErase)		/**< skip */
};


#define XCF_TILE_WIDTH 64
#define XCF_TILE_HEIGHT 64

/*!
	@enum		XcfImageType
	@constant	XCF_RGB_IMAGE
				A document with three colour channels (red, green and blue).
	@constant	XCF_GRAY_IMAGE
				A document with a single colour channel (white).
	@constant	XCF_INDEXED_IMAGE
				A document with an indexed colour channel (all such
				documents are converted to one of the above types after
				loading, as such elsewhere you do not need to account for
				this document type).
*/
typedef NS_ENUM(int, XcfImageType) {
	//! A document with three colour channels (red, green and blue).
	XCF_RGB_IMAGE NS_SWIFT_NAME(RGB),
	//! A document with a single colour channel (white).
	XCF_GRAY_IMAGE NS_SWIFT_NAME(gray),
	/*!
	 A document with an indexed colour channel (all such
	 documents are converted to one of the above types after
	 loading, as such elsewhere you do not need to account for
	 this document type).
	 */
	XCF_INDEXED_IMAGE NS_SWIFT_NAME(indexed)
};

/*!
	@enum		GimpImageType
	@constant   GIMP_RGB_IMAGE
				Specifies the layer's data is in the RGB format.
	@constant   GIMP_RGBA_IMAGE
				Specifies the layer's data is in the RGBA format.
	@constant   GIMP_GRAY_IMAGE
				Specifies the layer's data is in the GRAY format.
	@constant   GIMP_GRAYA_IMAGE
				Specifies the layer's data is in the GRAYA format.
	@constant   GIMP_INDEXED_IMAGE
				Specifies the layer's data is in the INDEXED format.
	@constant   GIMP_INDEXEDA_IMAGE
				Specifies the layer's data is in the INDEXEDA format.
*/
typedef NS_ENUM(int, GimpImageType) {
	//! Specifies the layer's data is in the RGB format.
	GIMP_RGB_IMAGE NS_SWIFT_NAME(RGB),
	//! Specifies the layer's data is in the RGBA format.
	GIMP_RGBA_IMAGE NS_SWIFT_NAME(RGBAlpha),
	//! Specifies the layer's data is in the GRAY format.
	GIMP_GRAY_IMAGE NS_SWIFT_NAME(gray),
	//! Specifies the layer's data is in the GRAYA format.
	GIMP_GRAYA_IMAGE NS_SWIFT_NAME(grayAlpha),
	//! Specifies the layer's data is in the INDEXED format.
	GIMP_INDEXED_IMAGE NS_SWIFT_NAME(indexed),
	//! Specifies the layer's data is in the INDEXEDA format.
	GIMP_INDEXEDA_IMAGE NS_SWIFT_NAME(indexedAlpha)
};


/*!
	@enum		k...Channels
	@constant	kAllChannels
				Specifies all channels.
	@constant	kPrimaryChannels
				Specifies the primary RGB channels in a colour image or the
				primary white channel in a greyscale image.
	@constant	kAlphaChannel
				Specifies the alpha channel.
*/
typedef NS_ENUM(int, SeaSelectedChannel) {
	//! Specifies all channels.
	SeaSelectedChannelAll,
	//! Specifies the primary RGB channels in a colour image or the
	//! primary white channel in a greyscale image.
	SeaSelectedChannelPrimary,
	//! Specifies the alpha channel.
	SeaSelectedChannelAlpha,
};

/*!
	@enum		k...Layer
	@constant	kActiveLayer
				Specifies the active layer.
	@constant	kAllLayers
				Specifies all layers.
	@constant	kLinkedLayers
				Specifies all linked layers.
*/
NS_ENUM(NSInteger) {
	//! Specifies the active layer.
	kActiveLayer = -1,
	//! Specifies all layers.
	kAllLayers = -2,
	//! Specifies all linked layers.
	kLinkedLayers = -3
};
#if 0
}
#endif
	
/*!
	@enum		k...Format
	@constant	kAlphaFirstFormat
				Specifies the alpha channel is first.
	@constant	kAlphaNonPremultipliedFormat
				Specifies the alpha is not premultiplied.
	@constant	kFloatingFormat
				Specifies the colour components are specified as floating point values.
*/
typedef NS_OPTIONS(unsigned int, GIMPBitmapFormat) {
	//! Specifies the alpha channel is first.
	GIMPBitmapFormatAlphaFirst = 1 << 0,
	//! Specifies the alpha is not premultiplied.
	GIMPBitmapFormatAlphaNonPremultiplied = 1 << 1,
	//! Specifies the colour components are specified as floating point values.
	GIMPBitmapFormatFloatingPoint = 1 << 2,
};


/*!
	@enum		k...Flip
	@constant	kHorizontalFlip
				Specifies a horizontal flip.
	@constant	kVerticalFlip
				Specifies a vertical flip.
 */
typedef NS_ENUM(int, SeaFlipType) {
	kHorizontalFlip NS_SWIFT_NAME(horizontal),
	kVerticalFlip NS_SWIFT_NAME(vertical)
};

/*!
	@defined	kMaxImageSize
	@discussion	Specifies the maximum size of an image, this restricts images to
				256 MB.
*/
#define kMaxImageSize 8192

/*!
	@defined	kMinImageSize
	@discussion	Specifies the minimum size of an image.
*/
#define kMinImageSize 1

/*!
	@defined	kMaxResolution
	@discussion	Specifies the maximum resolution of an image.
*/
#define kMaxResolution 8192

/*!
	@defined	kMinResolution
	@discussion	Specifies the minimum resolution of an image.
*/
#define kMinResolution 18


static const SeaSelectedChannel kAllChannels NS_SWIFT_UNAVAILABLE("Use .all instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectedChannelAll", 10.2, 10.8) = SeaSelectedChannelAll;
static const SeaSelectedChannel kPrimaryChannels NS_SWIFT_UNAVAILABLE("Use .primary instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectedChannelPrimary", 10.2, 10.8) = SeaSelectedChannelPrimary;
static const SeaSelectedChannel kAlphaChannel NS_SWIFT_UNAVAILABLE("Use .alpha instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("SeaSelectedChannelAlpha", 10.2, 10.8) = SeaSelectedChannelAlpha;

//! Specifies the alpha channel is first.
static const GIMPBitmapFormat kAlphaFirstFormat NS_SWIFT_UNAVAILABLE("Use .alphaFirst instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("GIMPBitmapFormatAlphaFirst", 10.2, 10.8) = GIMPBitmapFormatAlphaFirst;
//! Specifies the alpha is not premultiplied.
static const GIMPBitmapFormat kAlphaNonPremultipliedFormat NS_SWIFT_UNAVAILABLE("Use .alphaNonPremultiplied instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("GIMPBitmapFormatAlphaNonPremultiplied", 10.2, 10.8) = GIMPBitmapFormatAlphaNonPremultiplied;
//! Specifies the colour components are specified as floating point values.
static const GIMPBitmapFormat kFloatingFormat NS_SWIFT_UNAVAILABLE("Use .floatingPoint instead") NS_DEPRECATED_WITH_REPLACEMENT_MAC("GIMPBitmapFormatFloatingPoint", 10.2, 10.8) = GIMPBitmapFormatFloatingPoint;
