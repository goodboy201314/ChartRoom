//
//  JBScanCode.h
//  lanya
//
//  Created by xiangbin on 2017/4/15.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 *  委托
 */
@protocol JBScanCodeDelegate <NSObject>
@required
- (void)showScanCodeView;
@end

@interface JBScanCode : UIView

@property (nonatomic,strong) id<JBScanCodeDelegate> delegate;

+ (instancetype)scanCode;
@end
