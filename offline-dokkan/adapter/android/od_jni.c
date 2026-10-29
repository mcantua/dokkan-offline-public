#include "../od_bridge.h"
#include <jni.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Use real UTF-8 byte conversion: NewStringUTF/GetStringUTFChars use modified UTF-8
 * and can corrupt supplementary character names. Reject embedded C NUL bytes. */
static void throw_error(JNIEnv *e,const char *code){jclass c=(*e)->FindClass(e,"java/lang/IllegalStateException");if(c)(*e)->ThrowNew(e,c,code?code:"NATIVE_ERROR");}
static char *utf8(JNIEnv *e,jstring text) {
 if(!text)return NULL;
 jclass c=(*e)->FindClass(e,"java/lang/String");if(!c)return NULL;
 jmethodID m=(*e)->GetMethodID(e,c,"getBytes","(Ljava/lang/String;)[B");jstring encoding=(*e)->NewStringUTF(e,"UTF-8");
 jbyteArray a=m&&encoding?(jbyteArray)(*e)->CallObjectMethod(e,text,m,encoding):NULL;
 (*e)->DeleteLocalRef(e,c);if(encoding)(*e)->DeleteLocalRef(e,encoding);if(!a||(*e)->ExceptionCheck(e))return NULL;
 jsize n=(*e)->GetArrayLength(e,a);char *out=malloc((size_t)n+1);if(!out){(*e)->DeleteLocalRef(e,a);throw_error(e,"NO_MEMORY");return NULL;}
 (*e)->GetByteArrayRegion(e,a,0,n,(jbyte *)out);(*e)->DeleteLocalRef(e,a);
 if((*e)->ExceptionCheck(e)){free(out);return NULL;}
 if(memchr(out,0,(size_t)n)){free(out);throw_error(e,"INVALID_ARGUMENT");return NULL;}
 out[n]=0;return out;
}
static jstring java_string(JNIEnv *e,const char *text) {
 if(!text)return NULL;
 size_t n=strlen(text);if(n>INT32_MAX){throw_error(e,"RESULT_TOO_LARGE");return NULL;}
 jbyteArray a=(*e)->NewByteArray(e,(jsize)n);if(!a)return NULL;(*e)->SetByteArrayRegion(e,a,0,(jsize)n,(const jbyte *)text);
 jclass c=(*e)->FindClass(e,"java/lang/String");jmethodID m=c?(*e)->GetMethodID(e,c,"<init>","([BLjava/lang/String;)V"):NULL;
 jstring encoding=(*e)->NewStringUTF(e,"UTF-8");jstring result=m&&encoding?(jstring)(*e)->NewObject(e,c,m,a,encoding):NULL;
 (*e)->DeleteLocalRef(e,a);if(c)(*e)->DeleteLocalRef(e,c);if(encoding)(*e)->DeleteLocalRef(e,encoding);return result;
}
JNIEXPORT jlong JNICALL Java_com_personal_offlinedokkan_OfflineCore_nativeOpen(JNIEnv *e,jclass cls,jstring save,jstring master,jstring content) {
 (void)cls;char *s=utf8(e,save),*m=utf8(e,master),*c=utf8(e,content),*error=NULL;od_bridge *b=NULL;
 if(!(*e)->ExceptionCheck(e)&&od_bridge_open(s,m,c,&b,&error)<0)throw_error(e,error);
 free(s);free(m);free(c);od_bridge_free(error);return (jlong)(intptr_t)b;
}
JNIEXPORT jstring JNICALL Java_com_personal_offlinedokkan_OfflineCore_nativeExecute(JNIEnv *e,jclass cls,jlong handle,jstring operation,jstring profile,jstring command,jstring args,jboolean policy) {
 (void)cls;char *o=utf8(e,operation),*p=utf8(e,profile),*c=utf8(e,command),*a=utf8(e,args),*result=NULL,*error=NULL;jstring out=NULL;
 if(!(*e)->ExceptionCheck(e)){
  int rc=policy?od_bridge_execute_policy((od_bridge *)(intptr_t)handle,o,p,c,a,&result,&error):od_bridge_execute((od_bridge *)(intptr_t)handle,o,p,c,a,&result,&error);
  if(rc<0)throw_error(e,error);
  else out=java_string(e,result);
 }
 free(o);free(p);free(c);free(a);od_bridge_free(result);od_bridge_free(error);return out;
}
JNIEXPORT void JNICALL Java_com_personal_offlinedokkan_OfflineCore_nativeSave(JNIEnv *e,jclass cls,jlong handle,jstring path,jboolean importing) {
 (void)cls;char *p=utf8(e,path),*error=NULL;
 if(!(*e)->ExceptionCheck(e)){
  int rc=importing?od_bridge_import((od_bridge *)(intptr_t)handle,p,&error):od_bridge_export((od_bridge *)(intptr_t)handle,p,&error);
  if(rc<0)throw_error(e,error);
 }
 free(p);od_bridge_free(error);
}
JNIEXPORT void JNICALL Java_com_personal_offlinedokkan_OfflineCore_nativeClose(JNIEnv *e,jclass cls,jlong handle) {
 (void)e;(void)cls;od_bridge_close((od_bridge *)(intptr_t)handle);
}
