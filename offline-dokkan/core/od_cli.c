#include "od_core.h"
#include <stdio.h>
#include <string.h>
int main(int argc,char **argv) {
 if(argc!=8){fprintf(stderr,"usage: od-cli SAVE MASTER CONTENT PROFILE OPERATION COMMAND JSON\nCOMMAND may be - for profile.snapshot; OPERATION save.export/save.import takes a file path in JSON argument position (trusted CLI only).\n");return 2;}
 od_core *c=NULL;if(od_open(argv[1],argv[2],argv[3],&c)<0){fprintf(stderr,"OPEN_FAILED\n");return 1;}
 int rc;char *out=NULL;
 if(!strcmp(argv[5],"save.export"))rc=od_export_save(c,argv[7]);
 else if(!strcmp(argv[5],"save.import"))rc=od_import_save(c,argv[7]);
 else rc=od_execute(c,argv[5],argv[4],!strcmp(argv[6],"-")?NULL:argv[6],argv[7],&out);
 if(rc<0)fprintf(stderr,"%s\n",od_last_error(c));else puts(out?out:"{\"ok\":true}");
 od_free(out);od_close(c);return rc<0?1:0;
}
