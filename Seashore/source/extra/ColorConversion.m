#import "ColorConversion.h"

static int HLSValue(double n1, double n2, double hue)
{
	double value;

	if (hue > 255)
		hue -= 255;
	else if (hue < 0)
		hue += 255;
	if (hue < 42.5)
		value = n1 + (n2 - n1) * (hue / 42.5);
	else if (hue < 127.5)
		value = n2;
	else if (hue < 170)
		value = n1 + (n2 - n1) * ((170 - hue) / 42.5);
	else
		value = n1;

	return (int)(value * 255);
}

void SeaRGBtoHSV(int *red, int *green, int *blue)
{
	int r, g, b;
	double h, s, v;
	int min, max;
	int delta;

	h = 0.0;

	r = *red;
	g = *green;
	b = *blue;

	if (r > g) {
		max = MAX (r, b);
		min = MIN (g, b);
	} else {
		max = MAX (g, b);
		min = MIN (r, b);
    }

	v = max;

	if (max != 0)
		s = ((max - min) * 255) / (double) max;
	else
		s = 0;

	if (s == 0)
		h = 0;
	else {
		delta = max - min;
		if (r == max)
			h = (g - b) / (double) delta;
		else if (g == max)
			h = 2 + (b - r) / (double) delta;
		else if (b == max)
			h = 4 + (r - g) / (double) delta;
		h *= 42.5;

		if (h < 0)
			h += 255;
		if (h > 255)
			h -= 255;
	}

	*red   = h;
	*green = s;
	*blue  = v;
}

void SeaHSVtoRGB(int *hue, int *saturation, int *value)
{
	if (*saturation == 0) {
		*hue = *value;
		*saturation = *value;
		*value = *value;
    } else {
		double h = *hue * 6.0 / 255.0;
		double s = *saturation / 255.0;
		double v = *value / 255.0;

		double f = h - (int) h;
		double p = v * (1.0 - s);
		double q = v * (1.0 - (s * f));
		double t = v * (1.0 - (s * (1.0 - f)));

		switch ((int)h) {
			case 0:
				*hue = v * 255;
				*saturation = t * 255;
				*value = p * 255;
				break;
				
			case 1:
				*hue = q * 255;
				*saturation = v * 255;
				*value = p * 255;
				break;
				
			case 2:
				*hue = p * 255;
				*saturation = v * 255;
				*value = t * 255;
				break;
				
			case 3:
				*hue = p * 255;
				*saturation = q * 255;
				*value = v * 255;
				break;
				
			case 4:
				*hue = t * 255;
				*saturation = p * 255;
				*value = v * 255;
				break;
				
			case 5:
				*hue = v * 255;
				*saturation = p * 255;
				*value = q * 255;
				break;
		}
	}
}

void SeaRGBtoHLS (int *red, int *green, int *blue)
{
	double h, s;
	int min, max;
	
	int r = *red;
	int g = *green;
	int b = *blue;
	
	if (r > g) {
		max = MAX (r, b);
		min = MIN (g, b);
	} else {
		max = MAX (g, b);
		min = MIN (r, b);
	}
	
	double l = (max + min) / 2.0;

	if (max == min) {
		s = 0.0;
		h = 0.0;
	} else {
		int delta = (max - min);

		if (l < 128)
			s = 255 * (double)delta / (double)(max + min);
		else
			s = 255 * (double)delta / (double)(511 - max - min);

		if (r == max)
			h = (g - b) / (double)delta;
		else if (g == max)
			h = 2 + (b - r) / (double)delta;
		else
			h = 4 + (r - g) / (double)delta;

		h = h * 42.5;

		if (h < 0)
			h += 255;
		else if (h > 255)
			h -= 255;
	}

	*red = h;
	*green = l;
	*blue = s;
}

void SeaHLStoRGB(int *hue, int *lightness, int *saturation)
{
	double m1, m2;
	
	double h = *hue;
	double l = *lightness;
	double s = *saturation;
	
	if (s == 0) {
		/*  achromatic case  */
		*hue = l;
		*lightness = l;
		*saturation = l;
	} else {
		if (l < 128)
			m2 = (l * (255 + s)) / 65025.0;
		else
			m2 = (l + s - (l * s) / 255.0) / 255.0;
		
		m1 = (l / 127.5) - m2;
		
		/*  chromatic case  */
		*hue = HLSValue(m1, m2, h + 85);
		*lightness = HLSValue(m1, m2, h);
		*saturation = HLSValue(m1, m2, h - 85);
	}
}

