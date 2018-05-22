//
//  PrintController.h
//  Created by Muhammed Salih on 04/07/17.


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol PrintCompletedDelegate
-(void)done:(Boolean)status;
@end

@interface PrintController : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property(nonatomic,assign)id delegate;
@property (strong, nonatomic) NSMutableArray         *strings;


-(void)initController;

@end
