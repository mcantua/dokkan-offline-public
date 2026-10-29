#!/usr/bin/env python3
"""One-hop direct caller frontier for previously pinned original team readers.

Only exact selected body identities and direct call references are inspected.
A caller relationship alone does not identify an HTTP route or callback ABI.
"""
import argparse,bisect,hashlib,json,struct,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parents[2]/'tools'))
from objc_runtime_metadata import Image
sys.path.insert(0,str(HERE.parents[1]/'protocol-inspection'))
from inspect_handler_fields import function_starts,sections_and_symbols
from trace_tutorial_state import PREPARED_SHA

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--source',type=Path,required=True);p.add_argument('--frontier',type=Path,required=True)
 p.add_argument('--roles',nargs='+',required=True);p.add_argument('--private-output',type=Path,required=True);p.add_argument('--report',type=Path,required=True)
 a=p.parse_args();raw=a.source.read_bytes()
 if hashlib.sha256(raw).hexdigest()!=PREPARED_SHA or 'private' not in a.private_output.parts:raise ValueError('Source/output identity invalid')
 d=json.loads(a.frontier.read_text())
 if d.get('source_sha256')!=PREPARED_SHA:raise ValueError('Frontier identity changed')
 selected=[x for x in d['body_spans'] if x['role'] in a.roles]
 if len(selected)!=len(set(a.roles)) or not 1<=len(selected)<=8:raise ValueError('Role scope invalid')
 im=Image(raw);starts=function_starts(im);sections,_,_=sections_and_symbols(im);text,size,_,_=sections[b'__text'];spans=dict(zip(starts,starts[1:]+[text+size]))
 for x in selected:
  if spans.get(x['start'])!=x['end']:raise ValueError('Selected body boundary changed')
  off=im.offset(x['start'],x['end']-x['start'])
  if hashlib.sha256(raw[off:off+x['end']-x['start']]).hexdigest()!=x['sha256']:raise ValueError('Selected body pin changed')
 targets={x['start']:x for x in selected};callers={n:set() for n in targets};pos=im.offset(text,size)
 for rel in range(0,size-3,4):
  word=struct.unpack_from('<I',raw,pos+rel)[0]
  if word&0xfc000000!=0x94000000:continue
  delta=word&0x3ffffff
  if delta&0x2000000:delta-=0x4000000
  target=text+rel+delta*4
  if target not in targets:continue
  n=bisect.bisect_right(starts,text+rel)-1
  if n>=0 and starts[n] in spans and starts[n]!=target:callers[target].add(starts[n])
 rows=[];reports=[]
 for target,owners in callers.items():
  if len(owners)>24:raise ValueError('Caller scope exceeds bound')
  current=[]
  for start in sorted(owners):
   end=spans[start];length=end-start
   if not 0<length<=32768:raise ValueError('Caller body exceeds bound')
   off=im.offset(start,length);sha=hashlib.sha256(raw[off:off+length]).hexdigest();row={'role':targets[target]['role']+'_caller_'+str(len(current)+1),'start':start,'end':end,'bytes':length,'sha256':sha,'target_role':targets[target]['role']};rows.append(row);current.append({k:v for k,v in row.items() if k not in ('start','end')})
  reports.append({'reader_role':targets[target]['role'],'reader_sha256':targets[target]['sha256'],'direct_callers':current,'rebased_pointer_reference_count':sum(1 for value in im.rebases.values() if value==target)})
 a.private_output.parent.mkdir(parents=True,exist_ok=True);a.private_output.write_text(json.dumps({'source_sha256':PREPARED_SHA,'body_spans':rows},indent=2)+'\n')
 a.report.write_text(json.dumps({'kind':'original-team-reader-one-hop-caller-frontier','source_sha256':PREPARED_SHA,'readers':reports,'http_route_binding_verified':False,'runtime_execution_verified':False,'limits':['Direct call instruction relationships only; no inferred callback, request type or response root.','Private caller addresses retained only under ignored research output.']},indent=2)+'\n')
 print('One-hop team reader caller frontier saved; no route admitted.')
if __name__=='__main__':main()
