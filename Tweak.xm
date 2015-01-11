#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <notify.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>

#define IF_SPRINGBOARD if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])

//#import <jetslammed.h>
extern "C" int jetslammed_updateWaterMarkForPID(int highWatermarkMB, char* requester, int pid);

inline int PIDForProcessNamed(NSString *passedInProcessName) {
    // Thanks to http://stackoverflow.com/questions/6610705/how-to-get-process-id-in-iphone-or-ipad
    // Faster than ps,grep,etc

    int pid = 0;

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;

    size_t size;
    int st = sysctl(mib, (u_int)miblen, NULL, &size, NULL, 0);

    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;

    do {

        size += size / 10;
        newprocess = (kinfo_proc *)realloc(process, size);

        if (!newprocess) {
            if (process) {
                free(process);
            }
            return 0;
        }

        process = newprocess;
        st = sysctl(mib, (u_int)miblen, process, &size, NULL, 0);

    } while (st == -1 && errno == ENOMEM);

    if (st == 0) {

        if (size % sizeof(struct kinfo_proc) == 0) {
            int nprocess = (int)(size / sizeof(struct kinfo_proc));

            if (nprocess) {
                for (int i = nprocess - 1; i >= 0; i--) {
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];

                    if ([processName rangeOfString:passedInProcessName].location != NSNotFound) {
                        pid = process[i].kp_proc.p_pid;
                    }
                }

                free(process);
            }
        }
    }
    if (pid == 0) {
        NSLog(@"NINKEYBOARDMOREMEM: GET PROCESS %@ FAILED.", [passedInProcessName uppercaseString]);
    }

    return pid;
}

void addMem(CFNotificationCenterRef a, void *b, CFStringRef c, const void *d, CFDictionaryRef e) 
{
	int PID = PIDForProcessNamed(@"NinKeyboard");
	NSLog(@"Nin: calling jetslammed: %d", PID);
	char name[] = "NinKeyboardMemoryPlus";
	jetslammed_updateWaterMarkForPID(100, name, PID);
}

%ctor
{
	IF_SPRINGBOARD
	{
		NSLog(@"Nin: in springboard");
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &addMem, CFSTR("NinKeyboard_AddMem"), NULL, 0);
	}
	else
	{
		NSLog(@"Nin: adding memory");
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("NinKeyboard_AddMem"), NULL, NULL, NO);
	}
}