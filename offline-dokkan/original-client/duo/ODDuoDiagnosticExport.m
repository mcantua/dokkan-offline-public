#import "ODDuoDiagnosticExport.h"
#import "ODDuoDiagnosticReport.h"

void ODDuoPresentDiagnosticReport(NSDictionary *report, UIViewController *presenter,
        UIView *sourceView, dispatch_block_t completion) {
    if(!completion)return;
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{completion();});return;}
    if(!presenter.isViewLoaded||!presenter.view.window||presenter.presentedViewController||
       presenter.isBeingDismissed||presenter.isBeingPresented||
       presenter.view.window.windowScene.activationState!=UISceneActivationStateForegroundActive){completion();return;}
    NSData *payload=[NSJSONSerialization dataWithJSONObject:ODDuoShareableDiagnosticReport(report)
        options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:NULL];
    if(!payload.length){completion();return;}
    NSItemProvider *item=[[NSItemProvider alloc]init];item.suggestedName=@"OfflineDokkan-diagnostic.json";
    [item registerDataRepresentationForTypeIdentifier:@"public.json" visibility:NSItemProviderRepresentationVisibilityAll
        loadHandler:^NSProgress *(void (^reply)(NSData *,NSError *)){
            reply(payload,nil);return nil;
        }];
    UIActivityItemsConfiguration *configuration=[[UIActivityItemsConfiguration alloc]initWithItemProviders:@[item]];
    UIActivityViewController *sheet=[[UIActivityViewController alloc]initWithActivityItemsConfiguration:configuration];
    __block BOOL completed=NO;
    dispatch_block_t finish=^{if(completed)return;completed=YES;completion();};
    sheet.completionWithItemsHandler=^(UIActivityType activity,BOOL done,NSArray *items,NSError *failure){
        (void)activity;(void)done;(void)items;(void)failure;
        dispatch_async(dispatch_get_main_queue(),finish);
    };
    UIView *anchor=sourceView.window==presenter.view.window?sourceView:presenter.view;
    sheet.popoverPresentationController.sourceView=anchor;
    sheet.popoverPresentationController.sourceRect=anchor.bounds;
    @try{
        [presenter presentViewController:sheet animated:YES completion:^{
            if(!sheet.presentingViewController&&presenter.presentedViewController!=sheet)finish();
        }];
        // UIKit can reject presentation without an exception or completion.
        // Check the actual relationship on the next main turn, without a timer
        // or a repeated polling loop, so the tools entry cannot remain busy.
        dispatch_async(dispatch_get_main_queue(),^{
            if(!sheet.presentingViewController&&presenter.presentedViewController!=sheet)finish();
        });
    }
    @catch(NSException *exception){(void)exception;finish();}
}
