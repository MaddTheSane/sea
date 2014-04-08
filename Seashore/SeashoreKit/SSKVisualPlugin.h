//
//  SSKVisualPlugin.h
//  Seashore
//
//  Created by C.W. Betts on 4/8/14.
//
//

#import <SeashoreKit/SSKPlugin.h>

@interface SSKVisualPlugin : SSKPlugin
{
	__weak NSPanel *panel;
}
@property (strong) NSArray *nibArray;
@property (weak) IBOutlet NSPanel *panel;

@end
