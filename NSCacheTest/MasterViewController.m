//
//  MasterViewController.m
//  NSCacheTest
//
//  Created by Asano Satoshi on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import "ImageLoader.h"

static NSString *INSTAGRAM_CLIENT_ID = @"";

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSOperationQueue *_networkQueue;
    NSOperationQueue *_reloadQueue;
}
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Instagram";
        _networkQueue = [[NSOperationQueue alloc] init];
        _reloadQueue = [[NSOperationQueue alloc] init];
        _reloadQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];    

    if (!INSTAGRAM_CLIENT_ID.length) {
        @throw [NSException exceptionWithName:@"Instgram Client ID Not Found" reason:@"Get Instgram ID via http://instagr.am/developer/manage/" userInfo:nil];
    }    
    
    UIBarButtonItem *loadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadPhotos)];
    self.navigationItem.rightBarButtonItem = loadButton;

    [self loadPhotos];
}

// Instagramの写真をロードする
-(void)loadPhotos {    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/popular?client_id=%@", INSTAGRAM_CLIENT_ID]]];
    [NSURLConnection sendAsynchronousRequest:req queue:_networkQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        _objects = [json valueForKeyPath:@"data"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSDictionary *data = [_objects objectAtIndex:indexPath.row];
    
    // タイトルを挿入
    NSString *text = [data valueForKeyPath:@"caption.text"];
    cell.textLabel.text = [text description];
    NSString *imageUrl = [data valueForKeyPath:@"images.standard_resolution.url"];    
    
    // キャッシュから取得
    ImageLoader *imageLoader = [ImageLoader sharedInstance];    
    UIImage *image = [imageLoader cacedImageForUrl:imageUrl];    
    cell.imageView.image = image;
    
    if (!image) {        
        // 画像をロード
        [imageLoader loadImage:imageUrl completion:^(UIImage *image) {
            [self reloadData];            
        }];
    }
    return cell;
}

-(void)reloadData {
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
    if (_reloadQueue.operations.count) return;
    [_reloadQueue addOperation:op];
}

@end
