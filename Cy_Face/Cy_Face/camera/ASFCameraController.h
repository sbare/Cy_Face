#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol ASFCameraControllerDelegate <NSObject>
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
@end


@interface ASFCameraController : NSObject

@property (nonatomic, weak)     id <ASFCameraControllerDelegate>    delegate;

- (BOOL) setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation isFront:(BOOL)isFront;
- (void) startCaptureSession;
- (void) stopCaptureSession;

/*返回摄像头的方向**/
//  AVCaptureDevicePositionBack        = 1,
//AVCaptureDevicePositionFront       = 2,
-(NSInteger)frontBack;

/**
 是否处于监听中的状态
 */
-(BOOL)isRunning;

@end




