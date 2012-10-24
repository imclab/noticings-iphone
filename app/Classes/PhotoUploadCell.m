//
//  PhotoUploadCell.m
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadCell.h"
#import "UploadQueueManager.h"
#import "NoticingsAppDelegate.h"

@implementation PhotoUploadCell

-(void)displayPhotoUpload:(PhotoUpload *)upload;
{
    if (self.photoUpload == upload) {
        return;
    }
    DLog(@"showing %@", upload);
    if (self.photoUpload) {
        [self.photoUpload removeObserver:self forKeyPath:@"inProgress"];
        [self.photoUpload removeObserver:self forKeyPath:@"progress"];
        [self.photoUpload removeObserver:self forKeyPath:@"paused"];
    }
    self.photoUpload = upload;
    
    if (self.photoUpload) {
        if (self.photoUpload.asset) {
            self.imageView.image = [UIImage imageWithCGImage:self.photoUpload.asset.thumbnail];
        } else {
            self.imageView.image = [UIImage imageNamed:@"Icon"];
        }
        
        if (self.photoUpload.title == nil || [self.photoUpload.title isEqualToString:@""]) {
            self.mainTextLabel.text = @"No title";
        } else {
            self.mainTextLabel.text = self.photoUpload.title;
        }
        
        self.progressView.progress = 0;
        
        [self updateDetailText];
        
        [self.photoUpload addObserver:self
                           forKeyPath:@"inProgress"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        [self.photoUpload addObserver:self
                           forKeyPath:@"paused"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        [self.photoUpload addObserver:self
                           forKeyPath:@"progress"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        
    } else {
        self.imageView.image = nil;
        self.mainTextLabel.text = @"";
        self.detailTextLabel.text = @"";
    }

}

- (void)updateDetailText {
    if (self.photoUpload.paused) {
        self.progressView.hidden = YES;
        self.detailTextLabel.hidden = NO;
        self.detailTextLabel.text = @"Paused";

    } else if (self.photoUpload.inProgress) {
        self.detailTextLabel.text = @"";
        self.detailTextLabel.hidden = YES;
        self.progressView.progress = [self.photoUpload.progress floatValue];
        self.progressView.hidden = NO;
        return;

    } else {
        self.progressView.hidden = YES;
        self.detailTextLabel.hidden = NO;
        self.detailTextLabel.text = @"Queued";
    }
	//[self setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // KVO isn't main-thread
    dispatch_async(dispatch_get_main_queue(),^{
        [self updateDetailText];
    });
}


- (void)dealloc {
    [self displayPhotoUpload:nil];
}


@end
