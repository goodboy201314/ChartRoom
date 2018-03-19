//
//  JBDeviceCell.h
//  lanya
//
//  Created by xiangbin on 2017/3/14.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XBDeviceModel;

@interface JBDeviceCell : UITableViewCell
/** 数据模型 */
@property (nonatomic,strong) XBDeviceModel* device;
@end
