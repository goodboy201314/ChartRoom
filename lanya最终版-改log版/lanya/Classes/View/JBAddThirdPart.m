//
//  JBAddThirdPart.m
//  lanya
//
//  Created by xiangbin on 2017/4/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "JBAddThirdPart.h"

@implementation JBAddThirdPart

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+(instancetype)addThirdPart
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
}
- (IBAction)addAnother:(id)sender {
    if([self.delegate respondsToSelector:@selector(didAddThirdPart)]) {
        [self.delegate didAddThirdPart];
    }
}

- (IBAction)noAddAnother:(id)sender {
    if([self.delegate respondsToSelector:@selector(didNotAddThirdPart)]) {
        [self.delegate didNotAddThirdPart];
    }
}


@end
