//
//  PluginClass.m
//  Plugins
//
//  Created by robert engels on 12/30/18.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#import "PluginClass.h"

inline void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    int i, j, alphaPos, temp;
    
    for (i = 0; i < length; i++) {
        alphaPos = (i + 1) * spp - 1;
        if (input[alphaPos] == 255) {
            for (j = 0; j < spp; j++)
                output[i * spp + j] = input[i * spp + j];
        }
        else {
            if (input[alphaPos] != 0) {
                for (j = 0; j < spp - 1; j++)
                    output[i * spp + j] = int_mult(input[i * spp + j], input[alphaPos], temp);
                output[alphaPos] = input[alphaPos];
            }
            else {
                for (j = 0; j < spp; j++)
                    output[i * spp + j] = 0;
            }
        }
    }
}

inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    int i, j, alphaPos, newValue;
    double alphaRatio;
    
    for (i = 0; i < length; i++) {
        alphaPos = (i + 1) * spp - 1;
        if (input[alphaPos] == 255) {
            for (j = 0; j < spp; j++)
                output[i * spp + j] = input[i * spp + j];
        }
        else {
            if (input[alphaPos] != 0) {
                alphaRatio = 255.0 / input[alphaPos];
                for (j = 0; j < spp - 1; j++) {
                    newValue = 0.5 + input[i * spp + j] * alphaRatio;
                    newValue = MIN(newValue, 255);
                    output[i * spp + j] = newValue;
                }
                output[alphaPos] = input[alphaPos];
            }
            else {
                for (j = 0; j < spp; j++)
                    output[i * spp + j] = 0;
            }
        }
    }
}

/*
 convert NSImageRep to a format Seashore can work with, which is RGBA, or GrayA. If spp is 4, then RGBA, if 2, the GrayA
 */
void convertImageRep(NSImageRep *imageRep,unsigned char *dest,int width,int height,int spp) {
    
    NSColorSpaceName csname = MyRGBSpace;
    if (spp==2) {
        csname = MyGraySpace;
    }
    
    memset(dest,0,width*height*spp);
    
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&dest pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:csname bytesPerRow:width*spp
                                                                                     bitsPerPixel:8*spp];
    
    NSRect rect = NSMakeRect(0,0,width,height);
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow];
    [NSGraphicsContext setCurrentContext:ctx];
    [imageRep drawInRect:rect fromRect:rect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:NO hints:NULL];
    [NSGraphicsContext restoreGraphicsState];
    
    [bitmapWhoseFormatIKnow autorelease];
}

CIImage *createCIImage(PluginData *pluginData){
    int spp = [pluginData spp];
    int width = [pluginData width];
    int height = [pluginData height];
    
    int bbr = width*spp;
    
    unsigned char *data = [pluginData data];
    
    CGSize size = CGSizeMake(width,height);
    CGColorSpaceRef cs = spp > 2 ? MyRGBCS.CGColorSpace : MyGrayCS.CGColorSpace;
    CIFormat format = spp > 2 ? kCIFormatRGBA8 :kCIFormatLA8;
    
    NSData *idata = [NSData dataWithBytes:data length:(width*height*spp)];
    
    CIImage *inputImage = [[CIImage alloc] initWithBitmapData:idata bytesPerRow:bbr size:size format:format colorSpace:cs];
    
    return inputImage;
}

void renderCIImage(PluginData *pluginData,CIImage *image){
    int spp = [pluginData spp];
    int width = [pluginData width];
    int height = [pluginData height];
    IntRect selection = [pluginData selection];
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    
    unsigned char *overlay = [pluginData overlay];
    
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:image];
    
    convertImageRep(imageRep,overlay,width,height,spp);
    
    unsigned char *replace = [pluginData replace];
    int i;
    
    // set the replace mask
    if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
        for (i = 0; i < selection.size.height; i++) {
            memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
        }
    }
    else {
        memset(replace, 0xFF, width * height);
    }
}

void applyFilter(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    [inputImage autorelease];

    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

void applyFilters(PluginData *pluginData,CIFilter *filterA,CIFilter *filterB) {
    CIImage *inputImage = createCIImage(pluginData);
    [inputImage autorelease];
    
    [filterA setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filterA valueForKey: @"outputImage"];
    [filterB setValue:outputImage forKey:@"inputImage"];
    outputImage = [filterB valueForKey: @"outputImage"];

    renderCIImage(pluginData,outputImage);
}

void applyFilterBG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    [inputImage autorelease];
    
    CIColor *backColor = [CIColor colorWithCGColor:[[pluginData backColor] CGColor]];

    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:backColor forKey:@"inputColor"];
    CIImage *background = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:background forKey:@"inputBackgroundImage"];
    [filter setValue:outputImage forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

void applyFilterFG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    [inputImage autorelease];
    
    CIColor *foreColor = [CIColor colorWithCGColor:[[pluginData foreColor] CGColor]];
    
    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor"];
    CIImage *foreground = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setDefaults];
    [filter setValue:outputImage forKey:@"inputBackgroundImage"];
    [filter setValue:foreground forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}


void applyFilterFGBG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    [inputImage autorelease];
    
    CIColor *foreColor = [CIColor colorWithCGColor:[[pluginData foreColor] CGColor]];
    CIColor *backColor = [CIColor colorWithCGColor:[[pluginData backColor] CGColor]];
    
    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor"];
    CIImage *foreground = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setDefaults];
    [filter setValue:outputImage forKey:@"inputBackgroundImage"];
    [filter setValue:foreground forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:backColor forKey:@"inputColor"];
    CIImage *background = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:background forKey:@"inputBackgroundImage"];
    [filter setValue:outputImage forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

float calculateAngle(IntPoint point,IntPoint apoint){
    float angle;
    if (apoint.x - point.x == 0)
        angle = PI / 2.0;
    else if (apoint.x - point.x > 0)
        angle = atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    else if (apoint.x - point.x < 0 && point.y - apoint.y > 0)
        angle = PI - atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    else
        angle = -PI - atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    return angle;
}

int calculateRadius(IntPoint point,IntPoint apoint) {
    int radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
    radius = sqrt(radius);
    return radius;
}


