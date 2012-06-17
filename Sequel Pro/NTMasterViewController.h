//
//  NTMasterViewController.h
//  Sequel Pro
//
//  Created by Matt Langtree on 17/06/12.
//  Copyright (c) 2012 North of Three. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTDetailViewController;

@interface NTMasterViewController : UITableViewController

@property (strong, nonatomic) NTDetailViewController *detailViewController;

@end
