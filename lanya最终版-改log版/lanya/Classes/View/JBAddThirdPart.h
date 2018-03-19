//
//  JBAddThirdPart.h
//  lanya
//
//  Created by xiangbin on 2017/4/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol JBAddThirdPartDelegate <NSObject>
@required
- (void)didAddThirdPart;
- (void)didNotAddThirdPart;
@end

@interface JBAddThirdPart : UIView



@property (nonatomic,strong) id<JBAddThirdPartDelegate> delegate;
+ (instancetype)addThirdPart;
@end
