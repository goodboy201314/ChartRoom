//
//  XBSettingRmbCell.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBSettingRmbCell.h"

@implementation XBSettingRmbCell

- (IBAction)rmbMe:(UISwitch *)sender {
    if(self.rmbBlock) {
        self.rmbBlock(sender.on);
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
