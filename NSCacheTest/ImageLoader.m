//
//  ImageLoader.m
//  NSCacheTest
//
//  Created by Asano Satoshi on 3/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageLoader.h"

@interface ImageLoader () {
    NSOperationQueue *_networkQueue;
    NSCache *_imageCache;
    NSCache *_requestingUrls;
}
@end

@implementation ImageLoader 

+(id)sharedInstance {
    static ImageLoader *loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loader = [[self alloc] init];
    });
    return loader;
}

-(id)init {
    self = [super init];
    if (self) {
        _networkQueue = [[NSOperationQueue alloc] init];
        _requestingUrls = [[NSCache alloc] init]; // ただの便利なマルチスレッド用Dictionaryとして使っている
        
        _imageCache = [[NSCache alloc] init];
//        _imageCache.countLimit = 20;
//        _imageCache.totalCostLimit = 640 * 480 * 10;
    }
    return self;
}

-(UIImage *)cacedImageForUrl:(NSString *)imageUrl {
    return [_imageCache objectForKey:imageUrl];
}

-(void)loadImage:(NSString *)imageUrl completion:(void(^)(UIImage *image))completion {
    if ([_requestingUrls objectForKey:imageUrl]) return; // 既にリクエストされていればreturn
    [_requestingUrls setObject:@"lock" forKey:imageUrl];

    // 画像をロード
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20];

    NSCache *weakedImageCache = _imageCache; // 循環参照よけ
    NSCache *weakedRequestingUrl = _requestingUrls;

    [NSURLConnection sendAsynchronousRequest:req queue:_networkQueue completionHandler:^(NSURLResponse *res, NSData *imageData, NSError *error) {
//        [NSThread sleepForTimeInterval:0.5];
        UIImage *image = [UIImage imageWithData:imageData];        
        
        // キャッシュセット
        [weakedImageCache setObject:image forKey:imageUrl];        
//        [_imageCache setObject:image forKey:imageUrl cost:image.size.width * image.size.height];        

        [weakedRequestingUrl removeObjectForKey:imageUrl];
        completion(image); // callback
    }];     
}


@end
