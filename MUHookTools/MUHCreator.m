//
//  MUHCreator.m
//  MUHookTools
//
//  Created by 吴双 on 2020/2/22.
//  Copyright © 2020 Magic-Unique. All rights reserved.
//

#import "MUHCreator.h"

@interface MUHCreator ()

@property (nonatomic, strong, readonly) NSDate *date;

@end

@implementation MUHCreator

- (instancetype)init {
    self = [super init];
    if (self) {
        _map = [MUHReplaceMap new];
        _date = [NSDate date];
    }
    return self;
}

- (void)create {
    @try {
        [self __cloneTemplate];
        [self __modifyTemplate];
        [self __podInstall];
        [self __copyResources];
        [self __initGit];
        [self __openXcode];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

- (void)__cloneTemplate {
    CLInfo(@"Clone template...");
    [CLLoading start];
    if (self.distPath.isExist) {
        [self.distPath remove];
    }
    NSString *git = @"/usr/bin/git";
    CLLaunch(nil, git, @"clone", @"-b", @"0.1.0", @"--depth=1", @"git@gitee.com:pica/MUHookTemplate.git", self.distPath.string, nil);
    [[self.distPath subpathWithComponent:@".git"] remove];
    [CLLoading stop];
}

- (void)__modifyTemplate {
    CLInfo(@"Modify project info...");
    [CLLoading start];
    NSString *appBundleName = self.app.lastPathComponent.stringByDeletingPathExtension;
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[self.app subpathWithComponent:@"Info.plist"].string];
    NSString *appBundleId = info[@"CFBundleIdentifier"];
    NSString *appBundleShortVersion = info[@"CFBundleShortVersionString"];
    NSString *appBundleVersion = info[@"CFBundleVersion"];
    NSString *MinimumOSVersion = info[@"MinimumOSVersion"];
    
    MUHReplaceMap *map = [MUHReplaceMap new];
    map[@"MUH-APP-NAME"] = appBundleName;
    map[@"MUH-FRAMEWORK-NAME"] = [NSString stringWithFormat:@"%@Plugin", appBundleName];
    map[@"MUH_FRAMEWORK_NAME"] = [NSString stringWithFormat:@"%@Plugin", appBundleName];
    map[@"MUH-APP-BUNDLE-IDENTIFIER"] = appBundleId;
    map[@"MUH-APP-BUNDLE-SHORT-VERSION"] = appBundleShortVersion;
    map[@"MUH-APP-BUNDLE-VERSION"] = appBundleVersion;
    map[@"MUH-USER"] = NSUserName();
    map[@"MUH-ORGANIZATION-IDENTIFIER"] = [NSString stringWithFormat:@"com.%@", NSUserName()];
    map[@"MUH-ORGANIZATION-NAME"] = NSFullUserName();
    map[@"IPHONEOS_DEPLOYMENT_TARGET = 13.2;"] = [NSString stringWithFormat:@"IPHONEOS_DEPLOYMENT_TARGET = %@;", MinimumOSVersion];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    map[@"MUH-TIME-YEAR-MONTH-DAY"] = [dateFormatter stringFromDate:self.date];
    dateFormatter.dateFormat = @"yyyy";
    map[@"MUH-TIME-YEAR"] = [dateFormatter stringFromDate:self.date];
    
    MUPath *to = self.distPath;
    [map.items enumerateObjectsUsingBlock:^(MUHReplaceItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CLVerbose(@"Replace %@ => %@", obj.key, obj.value);
        [self inDirectory:to replace:obj.key to:obj.value];
    }];
    [CLLoading stop];
}

- (void)inDirectory:(MUPath *)directory replace:(NSString *)replace to:(NSString *)to {
    if (!directory.isDirectory) {
        CLError(@"%@ 不存在", directory.lastPathComponent);
        return;
    }
    [self _inDirectory:directory replace:replace to:to];
}

- (void)_inDirectory:(MUPath *)directory replace:(NSString *)replace to:(NSString *)to {
    [directory enumerateContentsUsingBlock:^(MUPath *content, BOOL *stop) {
        if (content.isFile) {
            [self _inFile:content replace:replace to:to];
            if ([content.lastPathComponent containsString:replace]) {
                NSString *name = content.lastPathComponent;
                name = [name stringByReplacingOccurrencesOfString:replace withString:to];
                MUPath *to = [content pathByReplacingLastPathComponent:name];
                CLVerbose(@"Move %@ to %@", content.lastPathComponent, to.lastPathComponent);
                [content moveTo:to autoCover:YES];
            }
        } else {
            [self _inDirectory:content replace:replace to:to];
            if ([content.lastPathComponent containsString:replace]) {
                NSString *name = content.lastPathComponent;
                name = [name stringByReplacingOccurrencesOfString:replace withString:to];
                MUPath *to = [content pathByReplacingLastPathComponent:name];
                CLVerbose(@"Move %@ to %@", content.lastPathComponent, to.lastPathComponent);
                [content moveTo:to autoCover:YES];
            }
        }
    }];
}

- (void)_inFile:(MUPath *)file replace:(NSString *)replace to:(NSString *)to {
    @autoreleasepool {
        NSString *content = [self read:file];
        content = [content stringByReplacingOccurrencesOfString:replace withString:to];
        [self save:content to:file];
    }
}

- (NSString *)read:(MUPath *)file {
    NSString *string = [NSString stringWithContentsOfFile:file.string encoding:NSUTF8StringEncoding error:nil];
    return string;
}

- (void)save:(NSString *)content to:(MUPath *)file {
    [content writeToFile:file.string atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)__podInstall {
    [CLLoading start];
    CLInfo(@"Install CocoaPods...");
    CLLaunch(self.distPath.string, @"/usr/local/bin/pod", @"install", nil);
    [CLLoading stop];
}

- (void)__copyResources {
    [CLLoading start];
    CLInfo(@"Copy Resources...");
    MUPath *packages = [self.distPath subpathWithComponent:@"Resources/Packages"];
    [packages createDirectoryWithCleanContents:NO];
    MUPath *from = self.app;
    MUPath *target = [packages subpathWithComponent:from.lastPathComponent];
    [from copyTo:target autoCover:YES];
    [CLLoading stop];
}

- (void)__initGit {
    [CLLoading start];
    NSString *git = @"/usr/bin/git";
    CLLaunch(self.distPath.string, git, @"init", nil);
    CLLaunch(self.distPath.string, git, @"add", @".", nil);
    CLLaunch(self.distPath.string, git, @"commit", @"-m", @"Init Project", nil);
    [CLLoading stop];
}

- (void)__openXcode {
    if (self.open) {
        CLInfo(@"Open in Xcode...");
        MUPath *workspace = [self.distPath contentsWithFilter:^BOOL(MUPath *content) {
            return [content isA:@"xcworkspace"];
        }].firstObject;
        if (workspace) {
            CLLaunch(nil, @"/usr/bin/open", workspace.string, nil);
        }
    }
}

@end
