//
//  render.hpp
//  Texturize
//
//  Created by C.W. Betts on 7/15/16.
//
//

#ifndef render_h
#define render_h

#include <stdbool.h>
#import <AppKit/AppKit.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

__private_extern int render(unsigned char *image_in, int width_in, int height_in, unsigned char *image_out, int width_out, int height_out, int overlap, int channels, bool tileable, NSProgressIndicator *progressBar);

#ifdef __cplusplus
}
#endif

	
#endif /* render_h */
