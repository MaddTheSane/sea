#define GIMP_ITEM

typedef struct
{
	gint width;
	gint height;
	guchar *data;
} GimpChannel;

static inline GimpChannel channel_make(unsigned char *data, int width, int height)
{
	GimpChannel channel;
	
	channel.width = width;
	channel.height = height;
	channel.data = data;
	
	return channel;
}
