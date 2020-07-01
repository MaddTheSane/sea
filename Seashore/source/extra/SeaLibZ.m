//
//  SeaLibZ.m
//  SeashoreKit
//
//  Created by C.W. Betts on 6/30/20.
//

#import "SeaLibZ.h"
#include <zlib.h>

static void
xcf_read_from_be(int    bpc,
				 uint8_t *data,
				 int    count)
{
	switch (bpc) {
		case 1:
			break;
			
		case 2:
		{
			uint16_t *d = (uint16_t *) data;
			
			for (int i = 0; i < count; i++) {
				d[i] = CFSwapInt16BigToHost(d[i]);
			}
		}
			break;
			
		case 4:
		{
			uint32_t *d = (uint32_t *) data;
			
			for (int i = 0; i < count; i++) {
				d[i] = CFSwapInt32BigToHost(d[i]);
			}
		}
			break;
			
		case 8:
		{
			uint64_t *d = (uint64_t *) data;
			
			for (int i = 0; i < count; i++) {
				d[i] = CFSwapInt64BigToHost(d[i]);
			}
		}
			break;
	}
}

BOOL SeaZDecompress(unsigned char *output, unsigned char *input, int inputLength, int width, int height, int spp)
{
	z_stream  strm;
	int       action;
	int       status;

	
	strm.next_out  = output;
	strm.avail_out = make_128((width * height * spp));

	strm.zalloc    = Z_NULL;
	strm.zfree     = Z_NULL;
	strm.opaque    = Z_NULL;
	strm.next_in   = input;
	strm.avail_in  = inputLength;

	status = inflateInit(&strm);
	if (status != Z_OK) {
		return NO;
	}
	
	action = Z_NO_FLUSH;

	while (status == Z_OK) {
		if (strm.avail_in == 0) {
			action = Z_FINISH;
		}
		
		status = inflate(&strm, action);
		
		if (status == Z_STREAM_END) {
			/* All the data was successfully decoded. */
			break;
		} else if (status == Z_BUF_ERROR) {
			//g_printerr("xcf: decompressed tile bigger than the expected size.");
			inflateEnd(&strm);
			return NO;
		} else if (status != Z_OK) {
			//g_printerr("xcf: tile decompression failed: %s", zError (status));
			inflateEnd(&strm);
			return NO;
		}
	}

	xcf_read_from_be(spp, output,
					 width * height);
	
	inflateEnd(&strm);

	return NO;
}

#if 0
static gboolean
xcf_load_tile_zlib (XcfInfo       *info,
                    GeglBuffer    *buffer,
                    GeglRectangle *tile_rect,
                    const Babl    *format,
                    gint           data_length)
{
  z_stream  strm;
  int       action;
  int       status;
  gint      bpp       = babl_format_get_bytes_per_pixel (format);
  gint      tile_size = bpp * tile_rect->width * tile_rect->height;
  guchar   *tile_data = g_alloca (tile_size);
  gsize     bytes_read;
  guchar   *xcfdata;

  /* Workaround for bug #357809: avoid crashing on g_malloc() and skip
   * this tile (return TRUE without storing data) as if it did not
   * contain any data.  It is better than returning FALSE, which would
   * skip the whole hierarchy while there may still be some valid
   * tiles in the file.
   */
  if (data_length <= 0)
    return TRUE;

  xcfdata = g_alloca (data_length);

  /* we have to read directly instead of xcf_read_* because we may be
   * reading past the end of the file here
   */
  g_input_stream_read_all (info->input, xcfdata, data_length,
                           &bytes_read, NULL, NULL);
  info->cp += bytes_read;

  if (bytes_read == 0)
    return TRUE;

  strm.next_out  = tile_data;
  strm.avail_out = tile_size;

  strm.zalloc    = Z_NULL;
  strm.zfree     = Z_NULL;
  strm.opaque    = Z_NULL;
  strm.next_in   = xcfdata;
  strm.avail_in  = bytes_read;

  /* Initialize the stream decompression. */
  status = inflateInit (&strm);
  if (status != Z_OK)
    return FALSE;

  action = Z_NO_FLUSH;

  while (status == Z_OK)
    {
      if (strm.avail_in == 0)
        {
          action = Z_FINISH;
        }

      status = inflate (&strm, action);

      if (status == Z_STREAM_END)
        {
          /* All the data was successfully decoded. */
          break;
        }
      else if (status == Z_BUF_ERROR)
        {
          g_printerr ("xcf: decompressed tile bigger than the expected size.");
          inflateEnd (&strm);
          return FALSE;
        }
      else if (status != Z_OK)
        {
          g_printerr ("xcf: tile decompression failed: %s", zError (status));
          inflateEnd (&strm);
          return FALSE;
        }
    }

  if (! xcf_data_is_zero (tile_data, tile_size))
    {
      if (info->file_version >= 12)
        {
          gint n_components = babl_format_get_n_components (format);

          xcf_read_from_be (bpp / n_components, tile_data,
                            tile_size / bpp * n_components);
        }

      gegl_buffer_set (buffer, tile_rect, 0, format, tile_data,
                       GEGL_AUTO_ROWSTRIDE);
    }

  inflateEnd (&strm);

  return TRUE;
}
#endif

int SeaZCompress(unsigned char *output, unsigned char *input, int width, int height, int spp)
{
	return 0;
}
