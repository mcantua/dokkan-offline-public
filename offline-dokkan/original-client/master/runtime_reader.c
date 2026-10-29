#include "runtime_reader.h"
#include "sqlite3.h"
#include <string.h>
static int hex64(const char *s) {
 if(!s||strlen(s)!=64)return 0;
 for(int i=0;i<64;i++)if(!((s[i]>='0'&&s[i]<='9')||(s[i]>='a'&&s[i]<='f')))return 0;
 return 1;
}
static int content(const char *s) {
 if(!s)return 0;
 if(!strncmp(s,"sparking:",9))s+=9;
 else if(!strncmp(s,"eclipse:",8))s+=8;
 return !strncmp(s,"sha256:",7)&&hex64(s+7);
}
static int name(const char *s) {
 if(!s||!s[0]||strlen(s)>100)return 0;
 for(;*s;s++)if(!((*s>='a'&&*s<='z')||(*s>='A'&&*s<='Z')||(*s>='0'&&*s<='9')||strchr("_.:-",*s)))return 0;
 return 1;
}
int od_runtime_card_id(const char *path,const char *content_id,const char *scope,
 const char *definition_id,int64_t version,const char *project_sha,const char *definition_sha,int64_t *out) {
 if(out)*out=0;
 if(!path||!path[0]||!out||!content(content_id)||!hex64(scope)||!name(definition_id)||version<1||!hex64(project_sha)||!hex64(definition_sha))return -1;
 sqlite3 *db=NULL;sqlite3_stmt *s=NULL;int result=-2;
 if(sqlite3_open_v2(path,&db,SQLITE_OPEN_READONLY|SQLITE_OPEN_NOFOLLOW,NULL)!=SQLITE_OK)goto done;
 if(sqlite3_db_readonly(db,"main")!=1)goto done;
 sqlite3_limit(db,SQLITE_LIMIT_LENGTH,24*1024*1024);
 sqlite3_limit(db,SQLITE_LIMIT_SQL_LENGTH,8192);
 sqlite3_busy_timeout(db,1000);
 if(sqlite3_exec(db,"PRAGMA query_only=ON;PRAGMA trusted_schema=OFF;BEGIN",NULL,NULL,NULL)!=SQLITE_OK)goto done;
 const char *check="SELECT count(*)=4 AND sum(key='format' AND value='od-derived-original-master-v1')=1 AND sum(key='scope' AND value=?1)=1 AND sum(key='content_id' AND value=?2)=1 AND sum(key='source_sha256' AND value=?3)=1 FROM od_runtime_meta";
 if(sqlite3_prepare_v2(db,check,-1,&s,NULL)!=SQLITE_OK)goto done;
 sqlite3_bind_text(s,1,scope,-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,2,content_id,-1,SQLITE_TRANSIENT);
 const char *tail=strrchr(content_id,':')+1;sqlite3_bind_text(s,3,tail,-1,SQLITE_TRANSIENT);
 if(sqlite3_step(s)!=SQLITE_ROW||sqlite3_column_int(s,0)!=1){result=-3;goto done;}
 sqlite3_finalize(s);s=NULL;
 const char *lookup="SELECT v.runtime_id FROM od_runtime_versions v JOIN od_runtime_rows r ON r.definition_id=v.definition_id AND r.version=v.version AND r.table_name='cards' AND r.row_id=v.runtime_id JOIN cards c ON c.id=v.runtime_id WHERE v.definition_id=?1 AND v.version=?2 AND v.project_sha256=?3 AND v.definition_sha256=?4";
 if(sqlite3_prepare_v2(db,lookup,-1,&s,NULL)!=SQLITE_OK)goto done;
 sqlite3_bind_text(s,1,definition_id,-1,SQLITE_TRANSIENT);sqlite3_bind_int64(s,2,version);
 sqlite3_bind_text(s,3,project_sha,-1,SQLITE_TRANSIENT);sqlite3_bind_text(s,4,definition_sha,-1,SQLITE_TRANSIENT);
 if(sqlite3_step(s)!=SQLITE_ROW||sqlite3_column_type(s,0)!=SQLITE_INTEGER){result=-4;goto done;}
 int64_t id=sqlite3_column_int64(s,0);
 if(id<97000001||id>98999001||id%1000!=1||sqlite3_step(s)!=SQLITE_DONE){result=-4;goto done;}
 sqlite3_finalize(s);s=NULL;
 if(sqlite3_exec(db,"COMMIT",NULL,NULL,NULL)!=SQLITE_OK)goto done;
 *out=id;result=0;
done:
 sqlite3_finalize(s);sqlite3_close(db);return result;
}
