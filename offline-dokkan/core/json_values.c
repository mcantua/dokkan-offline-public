#include "json_values.h"
#include <string.h>
int od_json_semantic_equal(sqlite3 *db,const char *a,const char *b){
 if(!db||!a||!b)return 0;
 const char *query=
 "WITH a AS(SELECT fullkey,CASE WHEN type IN('integer','real') THEN 'number' ELSE type END AS kind,CASE WHEN type IN('object','array') THEN NULL ELSE atom END AS atom FROM json_tree(?1)),"
 "b AS(SELECT fullkey,CASE WHEN type IN('integer','real') THEN 'number' ELSE type END AS kind,CASE WHEN type IN('object','array') THEN NULL ELSE atom END AS atom FROM json_tree(?2)) "
 "SELECT CASE WHEN json_valid(?1) AND json_valid(?2) THEN (SELECT count(*)=count(DISTINCT fullkey) FROM a) AND (SELECT count(*)=count(DISTINCT fullkey) FROM b) AND NOT EXISTS(SELECT * FROM a EXCEPT SELECT * FROM b) AND NOT EXISTS(SELECT * FROM b EXCEPT SELECT * FROM a) ELSE 0 END";
 /* The common retry avoids building/sorting two json_tree sets, while still rejecting invalid
  * JSON and duplicate object keys. Containers never compare their raw serialized value. */
 const char *same="SELECT CASE WHEN json_valid(?1) THEN (SELECT count(*)=count(DISTINCT fullkey) FROM json_tree(?1)) ELSE 0 END";
 sqlite3_stmt *s=NULL;int identical=!strcmp(a,b);
 if(sqlite3_prepare_v2(db,identical?same:query,-1,&s,NULL)!=SQLITE_OK)return -1;
 sqlite3_bind_text(s,1,a,-1,SQLITE_TRANSIENT);if(!identical)sqlite3_bind_text(s,2,b,-1,SQLITE_TRANSIENT);
 int rc=sqlite3_step(s),result=rc==SQLITE_ROW?sqlite3_column_int(s,0):-1;sqlite3_finalize(s);return result;
}
static void equal_function(sqlite3_context *context,int argc,sqlite3_value **argv){
 if(argc!=2||sqlite3_value_type(argv[0])==SQLITE_NULL||sqlite3_value_type(argv[1])==SQLITE_NULL){sqlite3_result_int(context,0);return;}
 const char *a=(const char *)sqlite3_value_text(argv[0]),*b=(const char *)sqlite3_value_text(argv[1]);
 int equal=od_json_semantic_equal(sqlite3_context_db_handle(context),a,b);
 if(equal<0)sqlite3_result_error(context,"JSON_COMPARISON_FAILED",-1);else sqlite3_result_int(context,equal);
}
int od_register_json_equal(sqlite3 *db){return sqlite3_create_function_v2(db,"od_json_equal",2,SQLITE_UTF8|SQLITE_DETERMINISTIC,NULL,equal_function,NULL,NULL,NULL);}
