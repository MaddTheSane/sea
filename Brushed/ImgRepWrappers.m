//
//  ImgRepWrappers.m
//  Brushed
//
//  Created by C.W. Betts on 8/18/16.
//
//

#import <Cocoa/Cocoa.h>
#import "ImgRepWrappers.h"

@implementation BitmapImageRepHelper

+ (nullable NSBitmapImageRep*)bitmapImageRepFromData:(NSData*)data error:(NSError**)error
{
	NSBitmapImageRep *imgRep;
	imgRep = [NSBitmapImageRep imageRepWithData:data];
	if (!imgRep) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
		}
	}
	return imgRep;
}

+ (nullable NSBitmapImageRep*)bitmapImageRepFromURL:(NSURL*)url error:(NSError**)error
{
	NSData *ourData = [[NSData alloc] initWithContentsOfURL:url options:(NSDataReadingMappedIfSafe) error:error];
	if (!ourData) {
		return nil;
	}
	
	return [self bitmapImageRepFromData:ourData error:error];
}

+ (nullable NSBitmapImageRep*)bitmapImageRepFromImage:(NSImage*)data error:(NSError**)error
{
	NSBitmapImageRep *imgRep;
	
	return imgRep;
}

@end


NSBitmapImageRep *bitmapImageRepFromDataWithError(NSData *data, NSError **error)
{
	NSBitmapImageRep *imgRep;
	
	return imgRep;
}

NSBitmapImageRep *bitmapImageRepFromURLWithError(NSURL *url, NSError **error)
{
	NSBitmapImageRep *imgRep;
	
	return imgRep;
}
