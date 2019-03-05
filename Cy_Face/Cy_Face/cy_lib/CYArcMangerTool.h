//
//  ArcMangerTool.h
//  ArcSoftFaceEngineDemo
//
//  Created by apple on 2019/2/26.
//  Copyright © 2019 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PersonalData.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** 时时回调人物模型数据 */
typedef void (^CYEndRecognitionCompletionBlock)(PersonalData *_personalData);

@interface CYArcMangerTool : NSObject

/**激活*/
+(NSString *)engineActiveWithAppid:(NSString *)appid sdkkey:(NSString *)sdkkey;

/**(视频开启监测下)注册人脸*/
+(void)registerPersonWithName:(NSString *)name;

/**从人脸库中进行动态人脸对比(其中参数view为内部openGLView所依附的父View,当匹配到人的时候会回调)*/
+(void)startRecognition:(id)view endRecognitionCompletionBlock:(CYEndRecognitionCompletionBlock)endRecognitionCompletionBlock;

/**终止人脸识别*/
+(void)endRecognition;

/**开始人脸识别*/
+(void)stopRecognition;

/**暂停人脸识别*/
+(void)startRecognition;

/**启动可切换前后置摄像头*/
+ (void)changeFront:(BOOL)isOn;

/**获取目前仓库里的人脸数据(ASFRPersond对象)*/
+(NSMutableArray *)personArr;

/**(图片识别)注册人脸*/
+(BOOL)registerPhotoPersonWithName:(NSString *)name;
/**两张图片对比(且识别选中图片的图片数据)*/
+(void)recognitionWithImage:(UIImage *)selectImage originImage:(UIImage *)originImage;

/**设置视频视图位置*/
+(void)setGLViewFrame:(CGRect)rect;

/*返回摄像头的方向**/
+(NSInteger)frontBack;

@end

NS_ASSUME_NONNULL_END
