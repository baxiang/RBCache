//
//  RBViewController.m
//  RBCache
//
//  Created by baxiang on 01/18/2017.
//  Copyright (c) 2017 baxiang. All rights reserved.
//

#import "RBViewController.h"
#import "RBCache.h"

@interface RBViewController ()

@end

@implementation RBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"%@", [[RBCache defaultCache] objectForKey:@"abc"]);
    NSLog(@"%@", [RBCache defaultCache][@"number"]);
    NSLog(@"%@", [[RBCache defaultCache] objectForKey:@"hosts"]);
    
    NSDictionary *hosts = @{@"nickName" : @"Asshole", @"Company" : @"ABCD", @"age" : @88};
    RBDiskCache *diskCache = [[RBDiskCache alloc] initWithDirectory:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"userInfo"]
                                       dbStoreThreshold:500];
    [diskCache setObject:@"Asshole" forKey:@"nickName"];
    [diskCache setObject:@"ABCD" forKey:@"Company"];
    [diskCache setObject:hosts forKey:@"Hosts"];
    
    NSLog(@"%@", [diskCache objectForKey:@"nickName"]);
    NSLog(@"%@", [diskCache objectForKey:@"Company"]);
    NSLog(@"%@", [diskCache objectForKey:@"Hosts"]);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
