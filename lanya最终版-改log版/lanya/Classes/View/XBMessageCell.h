//
//  XBMessageCell.h
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XBMessage;
@interface XBMessageCell : UITableViewCell
/**  模型数据  */
@property (nonatomic,strong) XBMessage* message;
@end
