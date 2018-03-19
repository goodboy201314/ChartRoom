//
//  XBSettingAutoLoginCell.h
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^XBSettingAutoLoginCellBlock)(BOOL);

@interface XBSettingAutoLoginCell : UITableViewCell
/**  自动登录block  */
@property (nonatomic,strong) XBSettingAutoLoginCellBlock autoLoginBlock;

@property (weak, nonatomic) IBOutlet UISwitch *autoLoginSwitch;
@end
