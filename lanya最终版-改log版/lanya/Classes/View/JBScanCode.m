//
//  JBScanCode.m
//  lanya
//
//  Created by xiangbin on 2017/4/15.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "JBScanCode.h"

@implementation JBScanCode

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+ (instancetype)scanCode
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];

}

- (IBAction)btnScan:(id)sender {
    if([self.delegate respondsToSelector:@selector(showScanCodeView)]) {
        [self.delegate showScanCodeView];
    }
}

@end
