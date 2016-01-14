//
//  QRViewController.h
//  Smerk
//
//  Created by Patrick Quinn on 21/12/2015.
//  Copyright © 2015 Sensipass. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>



@interface QRViewController : UIViewController {
    UIImage * image;
    AudioUnit outputUnit;
    double renderPhase;
}

- (void)displayImage:(NSString*)input;

@property (weak) IBOutlet UIImageView *cameraView;


@end
