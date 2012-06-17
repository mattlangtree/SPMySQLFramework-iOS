//
//  NTDetailViewController.h
//  Sequel Pro
//
//  Created by Matt Langtree on 17/06/12.
//  Copyright (c) 2012 North of Three. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
