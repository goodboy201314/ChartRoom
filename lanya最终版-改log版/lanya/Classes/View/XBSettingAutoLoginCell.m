//
//  XBSettingAutoLoginCell.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBSettingAutoLoginCell.h"

@implementation XBSettingAutoLoginCell
- (IBAction)autoLogin:(UISwitch *)sender {
    if(self.autoLoginBlock) {
        self.autoLoginBlock(sender.on);
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
