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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
