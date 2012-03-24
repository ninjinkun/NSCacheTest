//
//  MasterViewController.m
//  NSCacheTest
//
//  Created by Asano Satoshi on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "ImageLoader.h"

static NSString *INSTAGRAM_CLIENT_ID = @"";

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSOperationQueue *_networkQueue;
    NSOperationQueue *_reloadQueue;
}
@end

@implementation MasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"NSCacheTest";
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
    
    UIBarButtonItem *twitterButton = [[UIBarButtonItem alloc] initWithTitle:@"Twitter" style:UIBarButtonItemStyleBordered target:self action:@selector(loadTwitterTimeline)];    
    self.navigationItem.rightBarButtonItem = twitterButton;

    UIBarButtonItem *instagramButton = [[UIBarButtonItem alloc] initWithTitle:@"Instagram" style:UIBarButtonItemStyleBordered target:self action:@selector(loadInstagramPhotos)];    
    self.navigationItem.leftBarButtonItem = instagramButton;
}

-(void)loadTwitterTimeline {    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __weak MasterViewController *_self = self;
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if (error) return;        
        ACAccount *twitterAccount = [[accountStore accountsWithAccountType:accountType] objectAtIndex:0];
        NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:@"200", @"count", nil];
        TWRequest *req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/home_timeline.json"] parameters:param requestMethod:TWRequestMethodGET];
        req.account = twitterAccount;                
        [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSArray *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
            _objects = json;
            [_self reloadData];        
        }];
    }];      
}

// Instagramの写真をロードする
-(void)loadInstagramPhotos {    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/popular?client_id=%@", INSTAGRAM_CLIENT_ID]]];
    __weak MasterViewController *_self = self;
    [NSURLConnection sendAsynchronousRequest:req queue:_networkQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        _objects = [json valueForKeyPath:@"data"];
        [_self reloadData];
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
    
    NSString *text;
    NSString *imageUrl;

    if ([data objectForKey:@"text"]) { // isTwitter
        text = [data objectForKey:@"text"];
        imageUrl = [data valueForKeyPath:@"user.profile_image_url"];
    }
    else {
        text = [data valueForKeyPath:@"caption.text"];
        imageUrl = [data valueForKeyPath:@"images.standard_resolution.url"];    
    }
    cell.textLabel.text = [text description];
    
    
    
    
    // キャッシュから取得
    ImageLoader *imageLoader = [ImageLoader sharedInstance];    
    UIImage *image = [imageLoader cacedImageForUrl:imageUrl];    
    cell.imageView.image = image;
    
    if (!image) {        
        // 画像をロード
        __weak MasterViewController *_self = self; // 循環参照よけ
        [imageLoader loadImage:imageUrl completion:^(UIImage *image) {
            [_self reloadData];            
        }];
    }
    return cell;
}

-(void)reloadData {
    MasterViewController *_self = self;
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_self.tableView reloadData];
        });
    }];
    if (_reloadQueue.operations.count) return;
    [_reloadQueue addOperation:op];
}

@end
