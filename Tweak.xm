#import "Localize.h"
#import<UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#define CydiaController ((UITabBarController*)[[[UIApplication sharedApplication]keyWindow]rootViewController])

static UIBarButtonItem* countLabel = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
static UILabel* countLabelFooter;
static bool enableNavBar=YES;
static bool enableTable=YES;
static bool enabled=YES;
static bool countTotal=NO;
static int count;
static NSArray* arrayTitleTable;
static NSArray* arrayTitleNavBar;
static UITableView* tableTarget;

static NSString* stringFromArray(NSArray* array)
{
    NSString* string = [[NSString alloc]init];
    for(int k=0; k<[array count]-1;k++)
    {
         string=[string stringByAppendingString:[NSString stringWithFormat:@"%@%i",[array objectAtIndex:k],count]];
    }
    string=[string stringByAppendingString:((NSString*)[array objectAtIndex:[array count]-1])];
    return string;
}

static void updateTweakCount(UITableView* table){
    if(countTotal==YES && enabled==YES)
    {
        count=0;
        for (int k=0; k<table.numberOfSections ;k++)
        {
             count=count+[table numberOfRowsInSection:k];
        }
    }
    if(enableTable==YES && enabled==YES)
    {
        if (!countLabelFooter && table!= nil)
        {
           countLabelFooter=[[UILabel alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,40)];
           countLabelFooter.textColor=[UIColor lightGrayColor];
           countLabelFooter.textAlignment = NSTextAlignmentCenter;
           table.tableFooterView=countLabelFooter;
         }
         countLabelFooter.text=stringFromArray(arrayTitleTable);
     }
     else if(table.tableFooterView==countLabelFooter)
     {
          table.tableFooterView=[[UIView alloc]initWithFrame:CGRectMake(0,0,0,0)];
          countLabelFooter=nil;
     }
     countLabel.title=stringFromArray(arrayTitleNavBar);
     if (enabled== NO || enableNavBar==NO)
     {
        countLabel.title=@"";
     }
}

static void prepareTweakCount() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.alex.tweakcount2.plist"];
    countLabel.enabled=[[settings objectForKey:@"GreyColor" ]boolValue];
    if ([settings objectForKey:@"Enable"] != nil){
        enabled = [[settings objectForKey:@"Enable"]boolValue];
    }
    countTotal = [[settings objectForKey:@"CountTotal"]boolValue];
    if ([settings objectForKey:@"EnableNavBar" ] != nil){
        enableNavBar=[[settings objectForKey:@"EnableNavBar"]boolValue];
    }
    if ([settings objectForKey:@"EnableTable" ] != nil){
        enableTable=[[settings objectForKey:@"EnableTable"]boolValue];
    }
    arrayTitleTable=[@[ @"Total number of tweaks installed: ",@""]retain];
    if ([settings objectForKey:@"TitleTable" ] != nil && [[settings objectForKey:@"TitleTable"] isEqualToString:@""]== NO){
        arrayTitleTable=[[[settings objectForKey:@"TitleTable"] componentsSeparatedByString:@"#*"]retain];
    }
    arrayTitleNavBar = [@[@"Packages: ",@""]retain];
    if ([settings objectForKey:@"TitleNavBar" ] != nil && [[settings objectForKey:@"TitleNavBar"] isEqualToString:@""]== NO){
       arrayTitleNavBar=[[[settings objectForKey:@"TitleNavBar"] componentsSeparatedByString:@"#*"]retain];
    }
    NSFileManager* manager =[NSFileManager defaultManager];
    count=0;
    for (int i=0;i<[[manager contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil]count];i++)
    {
         if([((NSString*)[[manager contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil]objectAtIndex:i])rangeOfString:@".dylib"].location!=NSNotFound){
             count++;
         }
     }
     updateTweakCount(tableTarget);
     [settings release];    
}

%hook Cydia
-(void) applicationDidFinishLaunching:(id)arg1{ 
     prepareTweakCount();
     %orig;
}
- (void)applicationWillEnterForeground:(id)arg1{ 
    prepareTweakCount();
    %orig;
}
%end

%hook UINavigationController
-(void)viewWillAppear:(BOOL)animated{
     %orig;
     if ([self.tabBarItem.title isEqualToString:UCLocalize("INSTALLED")]== YES &&[((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]).rightBarButtonItem.title isEqualToString: UCLocalize("QUEUE")]==NO){
       ((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]).rightBarButtonItem= countLabel;
     }
}
%end

%hook UITableView
-(void)layoutSubviews{
    if([CydiaController isKindOfClass:[UITabBarController class]]==YES && CydiaController.selectedIndex== 3){
        tableTarget=self;
        updateTweakCount(self);
    }
    %orig;
}
%end

%hook UINavigationItem
-(void)setRightBarButtonItem:(UIBarButtonItem*)item{
    if(item == nil && enabled== YES){
          if([ self.rightBarButtonItem.title isEqualToString: UCLocalize("QUEUE")]==YES || self.rightBarButtonItem== countLabel){
               %orig(countLabel);
          }
    }
    else{
        %orig;
    }
}
%end