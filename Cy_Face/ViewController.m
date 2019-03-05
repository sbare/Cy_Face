//
//  ViewController.m
//  Cy_Face
//
//  Created by apple on 2019/3/4.
//  Copyright © 2019 Cy_Face. All rights reserved.
//

#import "ViewController.h"
#import "CYArcMangerTool.h"

#define glViewWidth [UIScreen mainScreen].bounds.size.width
#define glViewHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //人脸识别调用
    [self faceDistinguish];
}

-(void)faceDistinguish
{
      //激活
//    NSString *mr = [CYArcMangerTool engineActiveWithAppid:Cy_FaceKey sdkkey:Cy_FaceSecret];
//    NSLog(@"%@",mr);
    
    //开启监听
    //需要传入外面的view用于里面openglView的展示
    __weak typeof(self) weakSelf = self;
    [CYArcMangerTool startRecognition:weakSelf.view endRecognitionCompletionBlock:^(PersonalData *personalData) {
        //检测到人脸回调
        //personalData 自定义的人脸模型(包含姓名，三维数据，以及预测的年龄性别)
        if (personalData != nil) {//检测出人脸"
            //截图(截取视频流的图片)
//            CIImage *cImage = [CIImage imageWithCVPixelBuffer:personalData.imageBufferRef];
//            UIImage *image = [UIImage imageWithCIImage:cImage];
//            weakSelf.cptImage = image;
//            GMLog("%@",image);
        }else{//"未出人脸"
        }
    }];
    
    [CYArcMangerTool setGLViewFrame:CGRectMake(0, 0,glViewWidth, glViewHeight)];
    
}

@end
