#import "Localize.h"
#import<UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static UIBarButtonItem* countLabel;
static UILabel* countLabelFooter;
static bool enableNavBar=YES;
static bool enableTable=YES;
static bool greyColor=NO;
static NSString* titleTable=@"test";
static NSString* titleNavBar=@"yooo";
static bool enabled=YES;
static bool countTotal=NO;
static int count=0;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.alex.tweakcount2.plist"];
    if ([settings objectForKey:@"Enable" ] != nil)  
     {
           enabled = [[settings objectForKey:@"Enable"]boolValue];
     }
     if ([settings objectForKey:@"CountTotal"] != nil)  
     {
           countTotal = [[settings objectForKey:@"CountTotal"]boolValue];
     }
     if ([settings objectForKey:@"EnableNavBar" ] != nil)  
     {
           enableNavBar=[[settings objectForKey:@"EnableNavBar"]boolValue];
     }
     if ([settings objectForKey:@"EnableTable" ] != nil)  
      {
            enableTable=[[settings objectForKey:@"EnableTable"]boolValue];
      }
       if ([settings objectForKey:@"GreyColor" ] != nil)  
      {
          greyColor=[[settings objectForKey:@"GreyColor"]boolValue];
      }
      titleTable = @"Total number of tweaks installed: ";
      if ([settings objectForKey:@"TitleTable" ] != nil && [[settings objectForKey:@"TitleTable"] isEqualToString:@""]== NO)  
      {
          titleTable=[[settings objectForKey:@"TitleTable"]retain];
      }
      titleNavBar = @"Package: ";
      if ([settings objectForKey:@"TitleNavBar" ] != nil && [[settings objectForKey:@"TitleNavBar"] isEqualToString:@""]== NO)  
      {
          titleNavBar=[[settings objectForKey:@"TitleNavBar"]retain];
      }
      [settings release];    
}

%hook Cydia
- (void)applicationDidFinishLaunching:(id)arg1
{ 
    loadPrefs();
    if(enabled==YES && countTotal==NO)
    {
        NSFileManager* manager =[NSFileManager defaultManager];
        for (int i=0;i<[[manager contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil]count];i++)
        {
             if([((NSString*)[[manager contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil]objectAtIndex:i])rangeOfString:@"dylib"].location!=NSNotFound)
             {
                 count++;
             }
        }
     }
     %orig;
}
%end
%hook UINavigationController
-(void)viewWillAppear:(BOOL)animated
{
     %orig;
     if ([self.tabBarItem.title isEqualToString:UCLocalize("INSTALLED")]== YES &&((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]).rightBarButtonItems== nil && enabled== YES && enableNavBar==YES)
     {
          countLabel= [[UIBarButtonItem alloc]initWithTitle:[NSString stringWithFormat:@"%@%i",titleNavBar,count]style:UIBarButtonItemStylePlain target:nil action:nil];
         if (greyColor==YES)
         {
              countLabel.enabled=NO;
         }
         ((UINavigationItem*)[self.navigationBar.items objectAtIndex:0]).rightBarButtonItem= countLabel;
     }
}
%end
%hook UITableView
-(void)layoutSubviews
{
    if(((UITabBarController*)[[[UIApplication sharedApplication]keyWindow]rootViewController]).selectedIndex==3 && enabled== YES)
    {
        if(countTotal==YES)
        {
            count=0;
            for (int k=0; k<self.numberOfSections ;k++)
            {
                count=count+[self numberOfRowsInSection:k];
            }
        }
        if(enableTable==YES)
        {
            if (countLabelFooter == nil)
            {
                countLabelFooter=[[UILabel alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,40)];
                countLabelFooter.textColor=[UIColor lightGrayColor];
                countLabelFooter.textAlignment = NSTextAlignmentCenter;
                self.tableFooterView=countLabelFooter;
            }
            countLabelFooter.text=[NSString stringWithFormat:@"%@%i",titleTable,count];
         }
         if(enableNavBar==YES)
         {
             countLabel.title=[NSString stringWithFormat:@"%@%i",titleNavBar,count];
         }
    }
     %orig;
}
%end
%hook UINavigationItem
-(void)setRightBarButtonItem:(UIBarButtonItem*)item
{
    if(item == nil && enabled== YES)
    {
          if([ self.rightBarButtonItem.title isEqualToString: UCLocalize("QUEUE")]==YES || self.rightBarButtonItem== countLabel)
          {
               %orig(countLabel);
          }
    }
    else
    {
        %orig;
    }
}
%end