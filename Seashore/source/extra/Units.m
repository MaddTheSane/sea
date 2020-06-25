#include <math.h>
#include <tgmath.h>
#import "Units.h"

NSString *SeaStringFromPixels(int pixels, SeaUnits units, int resolution)
{
	NSString *result;
	
	switch (units) {
		case kInchUnits:
			result = [NSString stringWithFormat:@"%.2f", (float)pixels / resolution];
			break;
			
		case kMillimeterUnits:
			result = [NSString stringWithFormat:@"%.0f", (float)pixels / resolution * 25.4];
			break;
			
		default:
			result = [NSString stringWithFormat:@"%d", pixels];
			break;
	}
	return result;
}

int SeaPixelsFromFloat(CGFloat measure, SeaUnits units, int resolution)
{
	int result;
	
	switch (units) {
		case kInchUnits:
			result = round(measure * (CGFloat)resolution);
			break;
			
		case kMillimeterUnits:
			result = round(measure * (CGFloat)resolution / 25.4);
			break;
			
		default:
			result = measure;
			break;
	}
	
	return result;
}

NSString *SeaUnitsString(SeaUnits units)
{
	switch (units) {
		case kPixelUnits:
			return @"px";
		break;
		case kInchUnits:
			return @"in";
		break;
		case kMillimeterUnits:
			return @"mm";
		break;
	}
	return @"";
}
