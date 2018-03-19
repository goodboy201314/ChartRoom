//
//  XBSettingQuitCell.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBSettingQuitCell.h"
#import <UIKit/UIKit.h>


@implementation XBSettingQuitCell
// 单击了退出按钮
- (IBAction)quit:(id)sender {
    // 调用主程序的退出block
    if(self.quitBlock) {
        self.quitBlock();
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
