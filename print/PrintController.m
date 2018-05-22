//
//  PrintController
//  Created by Muhammed Salih on 04/07/17.
//

#import "PrintController.h"
#import "TransferService.h"
#import  "Print.h"
#define DELAY_TO_CLOSE 20

@interface PrintController ()

@end

@implementation PrintController

NSString *selectedPrinter;

bool allowPrint = true;
bool allDone = false;
int printedCount = 0 ;

-(void)initController{
    allowPrint = true;
    allDone = false;
    printedCount = 0 ;
    //  get the printer name // we have preselected the mane and saved it somevare
    selectedPrinter =[Print getPrinter];
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
}
-(BOOL)isSelectedPrinter:(NSString *)printerName{
    
    if(!printerName){
        return false;
    }
    if(selectedPrinter){
        if([selectedPrinter isEqualToString:printerName]){
            return true;
        }
        return false;
    }
    return true;
}

/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
     if(allowPrint){
         // not detecting device properly
   // [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    [self.centralManager scanForPeripheralsWithServices:nil options:0];
    }else{
        return;
    }
    NSLog(@"Scanning started");
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state != CBManagerStatePoweredOn) {
        [self closeWithError];
        return;
    }
    [self scan];
}

/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if(!allowPrint){
        return;
    }
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -10) {
        return;
    }
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -70) {
        return;
    }
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        NSLog(@"Connecting to peripheral %@", peripheral);
        if(allowPrint && peripheral.name && [self isSelectedPrinter:peripheral.name] ){
        [self.centralManager connectPeripheral:peripheral options:nil];
            [self.centralManager stopScan];
        }
    }
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error  {
    NSLog(@"Disconnected   to %@. (%@)", peripheral, [error localizedDescription]);
    
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self closeWithError];
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
CBPeripheral *periferalService;
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    // Stop scanning
   // [self.centralManager stopScan];
    //NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    periferalService = peripheral;
    // Search only for services that match our UUID
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];

}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        [self closeWithError];
        return;
    }
    
    // Discover the characteristic we want...
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    if(allowPrint)
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    if(error){
        [self closeWithError];
    }
    printedCount++ ;
    if(_strings.count == printedCount){
        [self closeWithSuccess];
    }
    
}
/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self closeWithError];
        return;
    }
    
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]|| [characteristic.UUID.UUIDString.uppercaseString containsString:TRANSFER_CHARACTERISTIC_UUID.uppercaseString]) {
            allowPrint = false;
            [_centralManager stopScan];
            [self printAll:peripheral andChar:characteristic];
            
            allDone = true;
            // if not complted with in 20 sec cancel the print else it will hang on for unlimited time
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(DELAY_TO_CLOSE)*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self closeWithError];
            });
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}
-(void)printAll:(CBPeripheral *)peripheral andChar :(CBCharacteristic *)characteristic{
    if(_strings)
        for (NSString *string in _strings) {
            [self print:string peri:peripheral andChar:characteristic];
        }
    
}
-(void)closeWithSuccess{
    if(allDone){
        return;
    }
    @try{
        if(_centralManager ){
            [_centralManager stopScan];
        }
    } @catch (NSException *exception) {
        
    }
    @try {
        if(_centralManager && periferalService){
            [self.centralManager cancelPeripheralConnection:periferalService];
        }
        allDone = true;
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    @try{
        if(_delegate){
            [_delegate done:true];
        }
    } @catch (NSException *exception) {
        
    }
    
}
-(void)closeWithError{
    if(allDone){
        return;
    }
    @try{
        if(_centralManager ){
            [_centralManager stopScan];
        }
    } @catch (NSException *exception) {
        
    }
    @try {
            if(_centralManager && periferalService){
                 [self.centralManager cancelPeripheralConnection:periferalService];
            }
        allDone = true;
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    @try{
        if(_delegate){
            [_delegate done:false];
        }
    } @catch (NSException *exception) {
        
    }

}
-(void)print:(NSString *)printString  peri:(CBPeripheral *)peripheral andChar :(CBCharacteristic *)characteristic{
    const char *bytes = [printString UTF8String];
    size_t length = [printString length];
    NSData *payload = [NSData dataWithBytes: bytes length:length];
    NSLog(@"Writing payload: %@ length of %zu", payload, length);
    [peripheral writeValue:payload forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    
}

@end
