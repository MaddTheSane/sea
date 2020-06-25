//
//  ImgRepWrappers.h
//  Brushed
//
//  Created by C.W. Betts on 8/18/16.
//
//

#ifndef ImgRepWrappers_h
#define ImgRepWrappers_h

#import <AppKit/NSBitmapImageRep.h>

NS_ASSUME_NONNULL_BEGIN

@interface BitmapImageRepHelper : NSObject

+ (nullable NSBitmapImageRep*)bitmapImageRepFromData:(NSData*)data error:(NSError**)error;
+ (nullable NSBitmapImageRep*)bitmapImageRepFromURL:(NSURL*)url error:(NSError**)error;
//+ (nullable NSBitmapImageRep*)bitmapImageRepFromImage:(NSImage*)data error:(NSError**)error;

@end


NS_ASSUME_NONNULL_END

#endif /* ImgRepWrappers_h */
