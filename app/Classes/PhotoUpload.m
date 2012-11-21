//
//  PhotoUpload.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUpload.h"

@implementation PhotoUpload

enum {
    ASSETURL_PENDINGREADS = 1,
    ASSETURL_ALLFINISHED = 0
};

-(NSString*)description;
{
    // this is the objective C introspection / toString() method
    return [NSString stringWithFormat:@"<%@ \"%@\" progress %@>", self.class, self.title, self.paused ? @"PAUSED" : self.progress];
}

- (id)initWithAsset:(ALAsset *)asset
{
	self = [super init];
	if (self != nil) {
		self.asset = asset;
        self.inProgress = FALSE;
        self.paused = FALSE;
		self.progress = @0.0f;
        self.uploadStatus = nil;

        self.privacy = PhotoUploadPrivacyPublic;
        self.location = [self.asset valueForProperty:ALAssetPropertyLocation];
        self.originalTimestamp = [self.asset valueForProperty:ALAssetPropertyDate];
        self.timestamp = [self.asset valueForProperty:ALAssetPropertyDate];
        DLog(@"Created PhotoUpload for Asset with location: %@ and timestamp: %@", self.location, self.timestamp);
        		
		if (self.location) {
			self.originalCoordinate = self.location.coordinate;
		} else {
			self.originalCoordinate = kCLLocationCoordinate2DInvalid;
		}
        self.coordinate = self.originalCoordinate;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:4 forKey:@"version"];
    [coder encodeObject:self.asset.defaultRepresentation.url forKey:@"assetUrl"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.tags forKey:@"tags"];
    [coder encodeInt:self.privacy forKey:@"privacy"];
    [coder encodeObject:self.flickrId forKey:@"flickrId"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.originalTimestamp forKey:@"originalTimestamp"];
    
    [coder encodeDouble:self.coordinate.latitude forKey:@"coordinate.latitude"];
    [coder encodeDouble:self.coordinate.longitude forKey:@"coordinate.longitude"];
    
    [coder encodeDouble:self.originalCoordinate.latitude forKey:@"originalCoordinate.latitude"];
    [coder encodeDouble:self.originalCoordinate.longitude forKey:@"originalCoordinate.longitude"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
	if (self != nil) {
        int version = [decoder decodeIntForKey:@"version"];
        if (version < 4) {
            return nil;
        }
        
        // create photo from asset url
        NSURL *assetURL = [decoder decodeObjectForKey:@"assetUrl"];
        if (assetURL) {
            // this doesn't actually work, alas. We can't get an asset from an URL
            // unless we still have the original assetmanager.
            // TODO - the only way round this is to get the resized image and save it out
            // to disk ourselves somewhere.
            self.asset = [PhotoUpload assetForURL:assetURL];
        }
        
        self.title = [decoder decodeObjectForKey:@"title"];
        self.tags = [decoder decodeObjectForKey:@"tags"];
        self.privacy = [decoder decodeIntForKey:@"privacy"];
        self.flickrId = [decoder decodeObjectForKey:@"flickrId"];
        self.location = [decoder decodeObjectForKey:@"location"];
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.originalTimestamp = [decoder decodeObjectForKey:@"originalTimestamp"];
        
        CLLocationCoordinate2D aCoordinate;
        aCoordinate.latitude = [decoder decodeDoubleForKey:@"coordinate.latitude"];
        aCoordinate.longitude = [decoder decodeDoubleForKey:@"coordinate.longitude"];
        self.coordinate = aCoordinate;
        
        CLLocationCoordinate2D anOriginalCoordinate;
        anOriginalCoordinate.latitude = [decoder decodeDoubleForKey:@"originalCoordinate.latitude"];
        anOriginalCoordinate.longitude = [decoder decodeDoubleForKey:@"originalCoordinate.longitude"];
        self.originalCoordinate = anOriginalCoordinate;
                
        self.inProgress = NO;
		self.progress = @0.0f;
        self.paused = YES;
    }
    return self;
}

+ (ALAsset *)assetForURL:(NSURL *)url {
    DLog(@"restoring asset from url %@", url);
    __block ALAsset *result = nil;
    __block NSError *assetError = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        result = asset;
        dispatch_semaphore_signal(sema);
    } failureBlock:^(NSError *error) {
        assetError = error;
        dispatch_semaphore_signal(sema);
    }];
    
    if ([NSThread isMainThread]) {
        while (!result && !assetError) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    else {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    dispatch_release(sema);
    
    return result;
}




@end
