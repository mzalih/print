//
//  Print.h
//  Created by Muhammed Salih on 19/04/18.

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TransferService.h"

@interface Print : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray         *availablePeripheralList;
@property (strong, nonatomic) CBCentralManager      *bleCentralManager;
@property (strong, nonatomic) UIViewController *parentVPC;
+(NSString *)getPrinter;
-(void)selectPrinter;
@end
