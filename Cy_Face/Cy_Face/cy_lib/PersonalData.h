//
//  PersonalData.h
//  ArcSoftFaceEngineDemo
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Sexual)
{
    //以下是枚举成员
    Man = 0,
    Women = 1,
    Dimness = 2
};

@interface PersonalData : NSObject
/**性别*/
@property(assign,nonatomic)NSInteger Sexual;
/**年龄*/
@property(assign,nonatomic)NSInteger age;
/**名字*/
@property(copy,nonatomic)NSString *name;

/**三维数据*/
@property(assign,nonatomic)float rollAngle;
@property(assign,nonatomic)float yawAngle;
@property(assign,nonatomic)float pitchAngle;


/**
 用于接受视频图片帧
 */
@property(assign,nonatomic)CVImageBufferRef imageBufferRef;

@end

NS_ASSUME_NONNULL_END
