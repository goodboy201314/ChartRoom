//
//  XBSettingQuitCell.h
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^XBSettingQuitCellBlock)();

@interface XBSettingQuitCell : UITableViewCell
/**  退出程序的block  */
@property (nonatomic,strong) XBSettingQuitCellBlock quitBlock;
@end
