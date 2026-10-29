#define _POSIX_C_SOURCE 200809L
#include "../../content/master_archive.h"
#include <jni.h>
#include <sqlite3.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* Descriptors come only from public ParcelFileDescriptor.dup/getFd inside the
 * trusted Java picker helper. No hidden libcore fields or page FD authority. */
JNIEXPORT void JNICALL Java_com_personal_offlinedokkan_OfflineMasterArchive_extract(JNIEnv *env,jclass type,jint source,jint output,jboolean sparking){
 (void)type;
 const char *error=NULL;od_master_archive_result result;
 if(od_master_archive_extract(source,output,sparking?"sparking":"eclipse",&result,&error)){
  jclass exception=(*env)->FindClass(env,"java/io/IOException");
  if(exception){(*env)->ThrowNew(env,exception,error?error:"MASTER_ARCHIVE_INVALID");(*env)->DeleteLocalRef(env,exception);}
 }
}

/* Private native migration only. Paths are fixed by OfflinePlayerStore, never
 * a WebView/picker field. SQLite backup reads a consistent legacy WAL snapshot;
 * opening the old file read only does not migrate or rewrite its contents. */
JNIEXPORT void JNICALL Java_com_personal_offlinedokkan_OfflinePlayerStore_snapshot(JNIEnv *env,jclass type,jstring source,jstring destination,jstring expectedContent){
 (void)type;sqlite3 *origin=NULL,*target=NULL;sqlite3_backup *backup=NULL;int output=-1,ok=0,created=0;
 const char *input=source?(*env)->GetStringUTFChars(env,source,NULL):NULL;
 const char *path=destination?(*env)->GetStringUTFChars(env,destination,NULL):NULL;
 const char *content=expectedContent?(*env)->GetStringUTFChars(env,expectedContent,NULL):NULL;
 if(!input||!path||(*env)->ExceptionCheck(env))goto done;
 output=open(path,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);if(output<0)goto done;created=1;
 if(close(output))goto done;
 output=-1;
 if(sqlite3_open_v2(input,&origin,SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK||sqlite3_open_v2(path,&target,SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK)goto done;
 sqlite3_stmt *size=NULL;int page_size=0;
 if(sqlite3_prepare_v2(origin,"PRAGMA page_size",-1,&size,NULL)==SQLITE_OK&&sqlite3_step(size)==SQLITE_ROW)page_size=sqlite3_column_int(size,0);
 sqlite3_finalize(size);if(page_size<512||page_size>65536)goto done;
 if(sqlite3_exec(target,"PRAGMA journal_mode=DELETE;PRAGMA synchronous=FULL;",NULL,NULL,NULL)!=SQLITE_OK)goto done;
 backup=sqlite3_backup_init(target,"main",origin,"main");if(!backup)goto done;
 int result=SQLITE_OK;struct timespec started,now;if(clock_gettime(CLOCK_MONOTONIC,&started))goto done;
 do{
  result=sqlite3_backup_step(backup,256);
  if((sqlite3_int64)sqlite3_backup_pagecount(backup)*page_size>512LL*1024*1024){result=SQLITE_TOOBIG;break;}
  if(result==SQLITE_BUSY||result==SQLITE_LOCKED)sqlite3_sleep(25);
  if(clock_gettime(CLOCK_MONOTONIC,&now)||now.tv_sec-started.tv_sec>=30){result=SQLITE_BUSY;break;}
 }while(result==SQLITE_OK||result==SQLITE_BUSY||result==SQLITE_LOCKED);
 int finish=sqlite3_backup_finish(backup);backup=NULL;
 if(result!=SQLITE_DONE||finish!=SQLITE_OK||sqlite3_exec(target,"PRAGMA journal_mode=DELETE",NULL,NULL,NULL)!=SQLITE_OK)goto done;
 sqlite3_stmt *check=NULL;if(sqlite3_prepare_v2(target,"PRAGMA quick_check",-1,&check,NULL)!=SQLITE_OK)goto done;
 ok=sqlite3_step(check)==SQLITE_ROW&&sqlite3_column_text(check,0)&&!strcmp((const char *)sqlite3_column_text(check,0),"ok")&&sqlite3_step(check)==SQLITE_DONE;sqlite3_finalize(check);
 if(ok&&content){
  check=NULL;ok=sqlite3_prepare_v2(target,"SELECT v FROM meta WHERE k='content'",-1,&check,NULL)==SQLITE_OK&&sqlite3_step(check)==SQLITE_ROW&&sqlite3_column_text(check,0)&&!strcmp((const char *)sqlite3_column_text(check,0),content)&&sqlite3_step(check)==SQLITE_DONE;sqlite3_finalize(check);
 }
done:
 if(backup)sqlite3_backup_finish(backup);
 if(target&&sqlite3_close(target)!=SQLITE_OK)ok=0;
 if(origin)sqlite3_close(origin);
 if(output>=0)close(output);
 if(path&&created&&!ok)unlink(path);
 if(input)(*env)->ReleaseStringUTFChars(env,source,input);
 if(path)(*env)->ReleaseStringUTFChars(env,destination,path);
 if(content)(*env)->ReleaseStringUTFChars(env,expectedContent,content);
 if(!ok&&!(*env)->ExceptionCheck(env)){
  jclass exception=(*env)->FindClass(env,"java/io/IOException");
  if(exception){(*env)->ThrowNew(env,exception,"LEGACY_SAVE_RECOVERY_REQUIRED");(*env)->DeleteLocalRef(env,exception);}
 }
}
