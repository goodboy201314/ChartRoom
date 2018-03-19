//
//  XBSettingIconCell.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBSettingIconCell.h"
@interface XBSettingIconCell()
@property (weak, nonatomic) IBOutlet UIButton *iconBtn;

@end

@implementation XBSettingIconCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // 登录用户的头像显示为圆形
    self.iconBtn.clipsToBounds=YES;
    self.iconBtn.layer.cornerRadius=self.iconBtn.frame.size.height / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
