//
//  MUHookTools+Creation.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import "MUHookTools+Creation.h"
#import "MUHCreator.h"
#import <Templator/Templator.h>

@implementation MUHookTools (Creation)

+ (void)__init_create {
    CLCommand *create = [[CLCommand mainCommand] defineSubcommand:@"create"];
    create.explain = @"Create a Xcode project to hook an ipa";
    create.addRequirePath(@"input").setExample(@"/path/to/*.{ipa|app}").setExplain(@"The ios app path.");
    create.setQuery(@"app-name").setAbbr('a').optional().setExample(@"AppName").setExplain(@"Custom app name.");
    create.setQuery(@"lib-name").setAbbr('l').optional().setExample(@"AppPlugin").setExplain(@"Dylib file name.");
    create.setQuery(@"template").setAbbr('t').optional().setExample(@"git-url|local-dir").setExplain(@"Template project");
    create.setFlag(@"no-pod-install").setExplain(@"Skip `pod install` step.");
    [create handleProcess:^int(CLCommand * _Nonnull command, CLProcess * _Nonnull process) {
        NSString *AppName = [process stringForQuery:@"app-name"];
        NSString *LibName = [process stringForQuery:@"lib-name"];
        BOOL no_pod_install = [process flag:@"no-pod-install"];
        
        MUPath *input = [MUPath pathWithString:[process pathForIndex:0]];
        MUPath *app = nil;
        if ([input isA:@"app"] && input.isDirectory) {
            app = input;
        }
        else if ([input isA:@"ipa"] && input.isFile) {
            CLInfo(@"Unzip ipa...");
            MUPath *temp = [[MUPath tempPath] subpathWithComponent:NSUUID.UUID.UUIDString];
            [temp createDirectoryWithCleanContents:YES];
            
            if (![SSZipArchive unzipFileAtPath:input.string toDestination:temp.string]) {
                CLError(@"Unzip failed.");
                return 1;
            }
            
            MUPath *Payload = [temp subpathWithComponent:@"Payload"];
            app = [Payload contentsWithFilter:^BOOL(MUPath *content) {
                return [content isA:@"app"] && content.isDirectory;
            }].firstObject;
            
            if (!app) {
                CLError(@"Can not find app bundle");
                return 1;
            }
        }
        else {
            CLError(@"The file is not exist.");
            return 1;
        }

        NSString *AppBundleName = app.lastPathComponent.stringByDeletingPathExtension;
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[app subpathWithComponent:@"Info.plist"].string];
        NSString *appBundleId = info[@"CFBundleIdentifier"];
        NSString *appBundleShortVersion = info[@"CFBundleShortVersionString"];
        NSString *appBundleVersion = info[@"CFBundleVersion"];
        NSString *MinimumOSVersion = info[@"MinimumOSVersion"];
        
        NSString *TARGET_NAME = AppName?:AppBundleName;
        
        TLCreator *creator = [[TLCreator alloc] init];
        
        NSString *template = process.queries[@"template"];
        if (!template) {
            [creator addGitClone:@"https://github.com/MUHook/Template.git" branch:TEMPLATE_VERSION];
        }
        else if ([template hasPrefix:@"http"] || [template hasPrefix:@"git@"]) {
            [creator addGitClone:template branch:@"master"];
        }
        else {
            [creator addStep:[TLStep step:@"Copy template" block:^(MUPath *path, id<TLInvoker> invoker) {
                MUPath *from = [MUPath pathWithString:template];
                MUPath *to = path;
                [from copyTo:to autoCover:YES];
            }]];
        }
        
        [creator addReplaceStep:^(TLReplaceStep *step) {
            [step replace:@"MUH-APP-NAME" to:AppName?:AppBundleName];
            [step replace:@"MUH-FRAMEWORK-NAME" to:LibName?:[NSString stringWithFormat:@"%@Plugin", AppName?:AppBundleName]];
            [step replace:@"MUH_FRAMEWORK_NAME" to:LibName?:[NSString stringWithFormat:@"%@Plugin", AppName?:AppBundleName]];
            [step replace:@"MUH-APP-BUNDLE-IDENTIFIER" to:appBundleId];
            [step replace:@"MUH-APP-BUNDLE-SHORT-VERSION" to:appBundleShortVersion];
            [step replace:@"MUH-APP-BUNDLE-VERSION" to:appBundleVersion];
            [step replace:@"MUH-USER" to:NSUserName()];
            [step replace:@"MUH-ORGANIZATION-IDENTIFIER" to:[NSString stringWithFormat:@"com.%@", NSUserName()]];
            [step replace:@"MUH-ORGANIZATION-NAME" to:NSFullUserName()];
            [step replace:@"IPHONEOS_DEPLOYMENT_TARGET = 13.2;" to:[NSString stringWithFormat:@"IPHONEOS_DEPLOYMENT_TARGET = %@;", MinimumOSVersion]];
            
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy/MM/dd";
            [step replace:@"MUH-TIME-YEAR-MONTH-DAY" to:[dateFormatter stringFromDate:date]];
            dateFormatter.dateFormat = @"yyyy";
            [step replace:@"MUH-TIME-YEAR" to:[dateFormatter stringFromDate:date]];
        }];
        if (!no_pod_install) {
            [creator addStep:[TLPodInstallStep new]];
        }
        [creator addStep:[TLStep step:@"Copy Resources" block:^(MUPath *path, id<TLInvoker> invoker) {
            MUPath *packages = [path subpathWithComponent:@"Resources/Packages"];
            [packages createDirectoryWithCleanContents:NO];
            MUPath *from = app;
            MUPath *target = [packages subpathWithComponent:[NSString stringWithFormat:@"%@.app", AppName?:AppBundleName]];
            [from copyTo:target autoCover:YES];
        }]];
        [creator addStep:[TLGitInitStep new]];
        if (!no_pod_install) {
            [creator addStep:({
                TLOpenStep *open = [TLOpenStep new];
                open.findFile = ^MUPath *(MUPath *path) {
                    MUPath *file = nil;
                    
                    file = file ?: [path contentsWithFilter:^BOOL(MUPath *content) {
                        return content.isDirectory && [content isA:@"xcworkspace"];
                    }].firstObject;
                    
                    file = file ?: [path contentsWithFilter:^BOOL(MUPath *content) {
                        return content.isDirectory && [content isA:@"xcodeproj"];
                    }].firstObject;
                    
                    return file;
                };
                open;
            })];
        }
#ifdef DEBUG
        [creator create:[[MUPath homePath] subpathWithComponent:TARGET_NAME]];
#else
        [creator create:[[MUPath path] subpathWithComponent:TARGET_NAME]];
#endif
        return 0;
    }];
}

@end
