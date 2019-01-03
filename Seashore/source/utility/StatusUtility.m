#import "StatusUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "LayerControlView.h"
#import "ToolboxUtility.h"
#import "SeaView.h"
// #import "WebSlider.h"
#import "SeaWindowContent.h"

@implementation StatusUtility
- (void)awakeFromNib
{
	[[SeaController utilitiesManager] setStatusUtility: self for:document];
	[(LayerControlView *)view setHasResizeThumb: NO];
	
	[self update];
}

- (IBAction)show:(id)sender
{
	[[[document window] contentView] setVisibility: YES forRegion: kStatusBar];
	[self update];
	[self updateZoom];
}

- (IBAction)hide:(id)sender
{
	[[[document window] contentView] setVisibility: NO forRegion: kStatusBar];
}

- (IBAction)toggle:(id)sender
{
	if([[[document window] contentView] visibilityForRegion: kStatusBar]) {
		[self hide:sender];
	}else{
		[self show:sender];
	}
}

- (void)update
{
	if(document){
		SeaContent *contents = [document contents];

		// Set the channel selections correction
		int i;
		for(i = 0; i < 3; i++){
			if([contents selectedChannel] == i){
				[[channelSelectionPopup itemAtIndex: i + 1] setState: YES];
			}else{
				[[channelSelectionPopup itemAtIndex: i + 1] setState: NO];
			}
		}
		
		[channelSelectionPopup selectItemAtIndex:([contents selectedChannel] + 1)];
		[channelSelectionPopup setEnabled:YES];
		[trueViewCheckbox setImage:[NSImage imageNamed:([contents trueView] ? @"trueview-sel" : @"trueview-not" )]];
		[trueViewCheckbox setEnabled:YES];
		
		int newUnits = [document measureStyle];
		NSString *statusString = @"";
		unichar ch = 0x00B7; // replace this with your code pointNSString
		NSString *divider = [NSString stringWithCharacters:&ch length:1];
		if([view frame].size.width > 445){
			statusString = [statusString stringByAppendingFormat: @"%@ %C %@ %@", StringFromPixels([contents width] , newUnits, [contents xres]), 0x00D7, StringFromPixels([contents height], newUnits, [contents yres]), UnitsString(newUnits)];
		}
		if([view frame].size.width > 480){
			statusString = [[NSString stringWithFormat:@"%.0f%% %@ ", [contents xscale] * 100, divider] stringByAppendingString: statusString];
		}
		if([view frame].size.width > 525){
			statusString = [statusString stringByAppendingFormat: @" %@ %d dpi", divider, [contents xres]];
		}
		if([view frame].size.width > 575){
			statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [contents type] ? @"Grayscale" : @"Full Color"];
		}
        
        SeaColorProfile *cp = [[document whiteboard] proofProfile];
        if(cp!=NULL && cp.cs!=NULL) {
            statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [cp desc]];
        }
		
		[dimensionLabel setStringValue: statusString];		

		[view setNeedsDisplay: YES];
	}else{
		// Disable the channel selections
		[channelSelectionPopup setEnabled:NO];
		[channelSelectionPopup selectItemAtIndex:0];
		[trueViewCheckbox setEnabled:NO];
		[trueViewCheckbox setImage:[NSImage imageNamed:@"trueview-not"]];
		
		[dimensionLabel setStringValue:@""];		
	}
}

-(void)updateZoom
{
	if(document){
		[zoomSlider setIntValue: (int)log2([[document contents] xscale])];	
	}else{
		[zoomSlider setEnabled: NO];
		[zoomSlider setIntValue: 0];
	}
}


- (IBAction)changeChannel:(id)sender
{
	[NSMenu popUpContextMenu:[sender menu] withEvent:[[NSEvent alloc] init]  forView: sender];
}

- (IBAction)channelChanged:(id)sender
{
	[[document contents] setSelectedChannel:[sender tag] % 10];
	[[document helpers] channelChanged];	
}

- (IBAction)trueViewChanged:(id)sender
{
	[[document contents] setTrueView:![[document contents] trueView]];
	[[document helpers] channelChanged];	
	[self update];
}

- (IBAction)changeZoom:(id)sender
{
	[(SeaView *)[document docView] zoomTo: [sender intValue]];
}

- (IBAction)zoomIn:(id)sender
{
	[(SeaView *)[document docView] zoomIn: self];
}

- (IBAction)zoomOut:(id)sender
{
	[(SeaView *)[document docView] zoomOut: self];
}

- (IBAction)zoomNormal:(id)sender
{
	[(SeaView *)[document docView] zoomNormal: self];
}

- (id)view
{
	return view;
}

@end
