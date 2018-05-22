//
//  Print.m
//  Created by Muhammed Salih on 19/04/18.

#import "Print.h"

@implementation Print

UITableView *selecatableTableView;
NSString *selectedName;
+(NSString *)getPrinter{
    return [[NSUserDefaults standardUserDefaults]
            stringForKey:@"savedPrinter"];;
}
-(BOOL)isSelectedPrinter:(NSString *)printerName{
    
    if(!printerName){
        return false;
    }
    if(selectedName){
        if([selectedName isEqualToString:printerName]){
            return true;
        }
        return false;
    }
    return false;
}

-(void)savePrinter:(NSString *)printer{
    [[NSUserDefaults standardUserDefaults] setObject:printer forKey:@"savedPrinter"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}
-(void)selectPrinter{
    selectedName = [Print getPrinter];
    _availablePeripheralList =[[NSMutableArray alloc]init];
     [self loadTable];
    _bleCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
   
}

-(void)loadTable{
    if(selecatableTableView){
        [selecatableTableView reloadData];
    }else{
        selecatableTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, _parentVPC.view.frame.size.width/2, _parentVPC.view.frame.size.height/2) style:UITableViewStylePlain];
        
        selecatableTableView.center = _parentVPC.view.center;
        
        [_parentVPC.view addSubview:selecatableTableView];
        selecatableTableView.dataSource = self;
        selecatableTableView.delegate = self;
        selecatableTableView.backgroundColor = [UIColor whiteColor];
        selecatableTableView.layer.borderColor = [UIColor grayColor].CGColor;
        selecatableTableView.layer.borderWidth =1;
        selecatableTableView.layer.cornerRadius = 10;
          [selecatableTableView reloadData];
    }
}
-(void)hideTable{
    if(selecatableTableView){
        [selecatableTableView removeFromSuperview];
        selecatableTableView = nil;
    }
    if(_bleCentralManager){
        [_bleCentralManager stopScan];
    }
}
//================
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(_bleCentralManager){
        [_bleCentralManager stopScan];
    }
    [self hideTable];
    if (indexPath.row >= _availablePeripheralList.count){
        return;
    }
    NSString *perif = _availablePeripheralList[indexPath.row];
    [self savePrinter:perif];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(_availablePeripheralList){
        return _availablePeripheralList.count +1;
    }
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"newFriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSString *perif = @"   CANCEL";
    if (_availablePeripheralList && indexPath.row < _availablePeripheralList.count){
        
        perif =_availablePeripheralList[indexPath.row];
        if([self isSelectedPrinter:perif]){
         //   cell.backgroundColor = UIColorFromRGB(0x196D44);
            cell.textLabel.textColor = [UIColor whiteColor];
        }else{
            cell.backgroundColor = [UIColor grayColor];
            cell.textLabel.textColor = [UIColor blackColor];
            
        }
        
    }else{
      //  cell.backgroundColor = UIColorFromRGB(0xF65646);
        cell.textLabel.textColor = [UIColor whiteColor];
    
    }
    cell.textLabel.text = perif;
    return cell;
}


- (void)scan
{
    @try{
        [self.bleCentralManager scanForPeripheralsWithServices:nil options:0];
    }
    @catch (NSException *exception) {}
   }



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
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
        if(peripheral.name && ![self contains:peripheral.name]){
            [_availablePeripheralList addObject:peripheral.name];
        }
    [self loadTable];
}
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    if (central.state != CBManagerStatePoweredOn) {
        
        // In a real app, you'd deal with all the states correctly
        NSLog(@"Turn bluetooth ON ");
        
        return;
    }
    [self scan];
}


-(BOOL) contains:(NSString*)string
{
    if(!string){
        return YES;
    }
    for (NSString* str in _availablePeripheralList) {
        if ([str isEqualToString:string])
            return YES;
    }
    return NO;
}

@end
