//
//  CacheURLProtocol.m
//  Noticings
//
//  Created by Tom Insam on 14/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import "CacheURLProtocol.h"
#import "CacheManager.h"
#import "NoticingsAppDelegate.h"

@implementation CacheURLProtocol

@synthesize request = request_;
@synthesize connection = connection_;
@synthesize data = data_;
@synthesize response = response_;

// property to stop recursive requests.
// http://stackoverflow.com/questions/2494831/intercept-web-requests-from-a-webview-flash-plugin
#define ANTIRECURSE_REQUEST_HEADER_TAG  @"x-mycustomurl-intercept"

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    if ([request valueForHTTPHeaderField:ANTIRECURSE_REQUEST_HEADER_TAG]) {
        return NO;
    }
    if ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client;
{
    // Add a custom header on the request to break the
    // infinite loop created by the [startLoading] below.
    NSMutableURLRequest* newRequest = [request mutableCopy];
    [newRequest setValue:@"recurse" forHTTPHeaderField:ANTIRECURSE_REQUEST_HEADER_TAG];
    
    self = [super initWithRequest:newRequest cachedResponse:cachedResponse client:client];
    
    if (self) {
        self.request = newRequest;
        self.connection = nil;
    }
    return self;
}

-(void)respond:(NSData*)data;
{
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:nil expectedContentLength:-1 textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
    [response release];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}


- (void)startLoading;
{
    self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

-(void)dealloc;
{
    [self stopLoading];
    [super dealloc];
}

- (void)stopLoading;
{
    if (self.connection) {
        [self.connection cancel];
    }
}

// NSURLConnection delegates (generally we pass these on to our client)
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    [[self client] URLProtocol:self didLoadData:newData];
    if (self.data) {
        [self.data appendData:newData];
    } else {
        self.data = [NSMutableData dataWithData:newData];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DLog(@"%@ failed to fetch %@: %@", self, self.request.URL, error);
    [[self client] URLProtocol:self didFailWithError:error];
    self.connection = nil;
    self.response = nil;
    self.data = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    self.connection = nil;
    self.response = nil;
    self.data = nil;
}


@end
