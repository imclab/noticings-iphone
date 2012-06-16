//
//  StreamViewController.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"
#import "UploadQueueManager.h"
#import "PhotoStreamManager.h"
#import "StreamPhotoViewCell.h"
#import "PhotoUploadCell.h"

@interface StreamViewController : PullRefreshTableViewController <PhotoStreamDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    IBOutlet StreamPhotoViewCell *photoViewCell;
    IBOutlet PhotoUploadCell *photoUploadCell;
    BOOL isRoot;
}

-(id)initWithPhotoStreamManager:(PhotoStreamManager*)manager;
-(void)updatePullText;
- (StreamPhoto *)streamPhotoAtIndexPath:(NSIndexPath*)indexPath;

@property (retain) PhotoStreamManager *streamManager;
@property (retain, nonatomic) PhotoUpload *maybeCancel;

@end
