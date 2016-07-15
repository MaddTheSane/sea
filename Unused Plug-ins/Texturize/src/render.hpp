//
//  render.hpp
//  Texturize
//
//  Created by C.W. Betts on 7/15/16.
//
//

#ifndef render_h
#define render_h

#import <AppKit/AppKit.h>

int render(unsigned char *image_in, int width_in, int height_in, unsigned char *image_out, int width_out, int height_out, int overlap, int channels, char tileable, NSProgressIndicator *progressBar);


#endif /* render_h */
