//
//  ImageLoader.h
//  NSCacheTest
//
//  Created by Asano Satoshi on 3/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageLoader : NSObject
+(id)sharedInstance;
-(UIImage *)cacedImageForUrl:(NSString *)imageUrl;
-(void)loadImage:(NSString *)imageUrl completion:(void(^)(UIImage *image))completion;
@end
