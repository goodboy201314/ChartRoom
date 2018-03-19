//
//  XBSettingRmbCell.h
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^XBSettingRmbCellBlock)(BOOL);

@interface XBSettingRmbCell : UITableViewCell
/**  记住用户名block  */
@property (nonatomic,strong) XBSettingRmbCellBlock rmbBlock;

@property (weak, nonatomic) IBOutlet UISwitch *rmbSwitch;

@end
