//
//  ViewController.m
//  print
//
//  Created by Muhammed salih T A on 22/05/18.
//  Copyright © 2018 Muhammed salih T A. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *printButton;
@property (weak, nonatomic) IBOutlet UIButton *printSelectButton;

@end

@implementation ViewController

PrintController * printController ;
Print *printSelecter;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)print:(id)sender {
    [_printButton setEnabled:false];
    NSMutableArray *data = [[NSMutableArray alloc]init];
    [data addObject: @"^XA"];
    [data addObject: @"^CFA,30"];
    [data addObject: @"^FO50,420^FDHello World^FS"];
    [data addObject: @"^FO50,500^GB700,1,3^FS"];
    [data addObject: @"^XZ"];
    if(printController == nil){
        printController = [[PrintController alloc]init];
    }
    printController.strings = data;
    printController.delegate = self;
    [printController initController];
}
-(void)done:(Boolean)status{
    NSLog(@"print status log here");
    [_printButton setEnabled:true];
    
}
- (IBAction)selectPrinter:(id)sender {
    if(printSelecter == nil){
        printSelecter  = [[Print alloc]init];
    }
    printSelecter  = [[Print alloc]init];
    printSelecter.parentVPC = self;
    [printSelecter selectPrinter];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
