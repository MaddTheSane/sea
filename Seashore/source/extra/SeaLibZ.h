//
//  SeaLibZ.h
//  SeashoreKit
//
//  Created by C.W. Betts on 6/30/20.
//

#import <Foundation/Foundation.h>
#ifdef SEASYSPLUGIN
#import "Globals.h"
#else
#import <SeashoreKit/Globals.h>
#endif


BOOL SeaZDecompress(unsigned char *output, unsigned char *input, int inputLength, int width, int height, int spp);

int SeaZCompress(unsigned char *output, unsigned char *input, int width, int height, int spp);
