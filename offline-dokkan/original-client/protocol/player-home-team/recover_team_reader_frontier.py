#!/usr/bin/env python3
"""Recover original team DTO candidates from five exact reviewed field names.

Partial ADRP/ADD literal references identify candidate bodies, not routes or a
complete DTO. Exact selected spans/hashes are saved privately for decompilation.
No played-account data, unknown strings or source keys are exported.
"""
import argparse,bisect,hashlib,json,struct,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parents[2]/'tools'))
from objc_runtime_metadata import Image
sys.path.insert(0,str(HERE.parents[1]/'protocol-inspection'))
from inspect_handler_fields import function_starts,sections_and_symbols
from trace_tutorial_state import PREPARED_SHA
FIELDS=frozenset(('user_card_teams','selected_team_num','selected_kobetu_team_num','user_card_ids','team_bgm_filename'))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,required=True)
    p.add_argument('--private-output',type=Path,required=True)
    p.add_argument('--report',type=Path,required=True)
    a=p.parse_args();raw=a.source.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=PREPARED_SHA:raise ValueError('Source pin changed')
    if 'private' not in a.private_output.parts:raise ValueError('Detailed output must stay private')
    im=Image(raw);starts=function_starts(im);sections,_,_=sections_and_symbols(im)
    text,size,_,_=sections[b'__text'];spans=dict(zip(starts,starts[1:]+[text+size]))
    cstart,csize,_,_=sections[b'__cstring'];coff=im.offset(cstart,csize)
    literals={};counts={f:0 for f in FIELDS}
    for f in FIELDS:
        needle=f.encode()+b'\0';at=coff
        while True:
            at=raw.find(needle,at,coff+csize)
            if at<0:break
            if at==coff or raw[at-1]==0:
                literals[cstart+at-coff]=f;counts[f]+=1
            at+=len(needle)
    off=im.offset(text,size);refs=[]
    for rel in range(0,size-32,4):
        word=struct.unpack_from('<I',raw,off+rel)[0]
        if word&0x9f000000!=0x90000000:continue
        imm=(((word>>5)&0x7ffff)<<2)|((word>>29)&3)
        if imm&0x100000:imm-=0x200000
        reg=word&31;page=((text+rel)&~4095)+(imm<<12)
        for distance in range(4,32,4):
            op=struct.unpack_from('<I',raw,off+rel+distance)[0];rd=op&31;rn=(op>>5)&31
            if op&0xff000000==0x91000000 and rn==reg:
                target=page+(((op>>10)&4095)<<(12 if op&(1<<22) else 0))
                if target in literals:
                    pc=text+rel+distance;n=bisect.bisect_right(starts,pc)-1
                    if n>=0 and text<=starts[n]<spans[starts[n]]<=text+size:
                        refs.append({'start':starts[n],'instruction':pc,'field':literals[target]})
            if rd==reg:break
            if op&0xfc000000==0x94000000 and reg<=18:break
            if op&0x7c000000==0x14000000:break
    selected=sorted({r['start'] for r in refs});bodies=[];public=[]
    if len(selected)>32:raise ValueError('Team reader candidates exceed bound')
    for start in selected:
        end=spans[start];length=end-start
        if not 0<length<=32768:raise ValueError('Candidate body exceeds bound')
        pos=im.offset(start,length);sha=hashlib.sha256(raw[pos:pos+length]).hexdigest()
        fields=sorted({r['field'] for r in refs if r['start']==start})
        role='team_reader_candidate_'+str(len(bodies)+1)
        bodies.append({'role':role,'start':start,'end':end,'bytes':length,'sha256':sha,'allowlisted_fields':fields})
        public.append({k:v for k,v in bodies[-1].items() if k not in ('start','end')})
    a.private_output.parent.mkdir(parents=True,exist_ok=True)
    a.private_output.write_text(json.dumps({'source_sha256':PREPARED_SHA,'body_spans':bodies,'field_xrefs':refs},indent=2)+'\n')
    a.report.write_text(json.dumps({'kind':'original-current-team-reader-frontier','source_sha256':PREPARED_SHA,'literal_counts':counts,'candidate_bodies':public,'dto_ownership_verified':False,'home_team_route_admitted':False,'native_runtime_execution_verified':False,'limits':['Exact five reviewed team-field names only.','ADRP/immediateADD lookahead is partial static discovery; references do not prove model ownership, response root, requiredness or request route.','Detailed instruction sites and body addresses remain private.']},indent=2)+'\n')
    print('Exact team-field reader frontier saved; no DTO or route admitted.')
if __name__=='__main__':main()
