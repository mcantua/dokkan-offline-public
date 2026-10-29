#!/usr/bin/env python3
"""Pinned current-client Foundation transport method inspection, no execution.

Public output contains only reviewed selectors, body hashes and source limits.
Addresses, annotated instructions and call targets remain ignored/private.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[4]
sys.path[:0]=[str(ROOT/'offline-dokkan/tools'),str(ROOT/'offline-dokkan/original-client/content'),str(ROOT/'downloads/capstone/runtime')]
from objc_runtime_metadata import Image
from inspect_master_root import SOURCE_HASH,SOURCE_BYTES,function_starts,imports,stub
import inspect_asset_probes
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN

METHODS=frozenset(('startRequest:','connection:didReceiveResponse:','connection:didReceiveData:',
 'connection:didFailWithError:','connectionDidFinishLoading:','cancel','dealloc','init',
 'responseData','setResponseData:','responseCode','setResponseCode:','responseHeader','setResponseHeader:',
 'statusString','setStatusString:','request','setRequest:'))
SELECTORS=frozenset(('initWithRequest:delegate:','initWithRequest:delegate:startImmediately:',
 'sendAsynchronousRequest:queue:completionHandler:','dataTaskWithRequest:completionHandler:',
 'sessionWithConfiguration:delegate:delegateQueue:','scheduleInRunLoop:forMode:','start','cancel',
 'setHTTPMethod:','setHTTPBody:','setValue:forHTTPHeaderField:','setAllHTTPHeaderFields:',
 'HTTPBody','HTTPBodyStream','HTTPMethod','allHTTPHeaderFields','URL','statusCode','allHeaderFields',
 'setLength:','appendData:','setResponseData:','setResponseCode:','setResponseHeader:',
 'responseData','responseCode','responseHeader','statusString','setStatusString:','length',
 'sharedSession','currentRunLoop','mainRunLoop','mainQueue','setDelegate:','setRequest:',
 'performSelectorOnMainThread:withObject:waitUntilDone:','retain','release','autorelease',
 'description','localizedDescription','initWithCapacity:','init','alloc','copy','mutableCopy'))
IMPORTS=frozenset(('_objc_msgSend','_objc_msgSendSuper2','_objc_release','_objc_retain',
 '_objc_storeStrong','_objc_autoreleaseReturnValue','_objc_retainAutoreleasedReturnValue'))
inspect_asset_probes.SELECTORS=SELECTORS


def inspect(source,private,report):
 raw=source.read_bytes()
 if len(raw)!=SOURCE_BYTES or hashlib.sha256(raw).hexdigest()!=SOURCE_HASH:raise ValueError('Wrong pinned engine')
 if 'private' not in private.parts:raise ValueError('Details must remain private')
 image=Image(raw);starts=function_starts(image);spans=dict(zip(starts,starts[1:]));bindings=imports(image)
 decoder=Cs(CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN);decoder.detail=True
 address,size=image.sections[b'__objc_classlist'];found=[]
 for offset in range(0,size,8):
  cls=image.pointer(address+offset);ro=image.class_ro(cls)
  if image.string(image.pointer(ro+24))!='HttpAsynConnection':continue
  table=image.pointer(ro+32);flags,count=image.at('II',table);relative=bool(flags&0x80000000);direct=bool(flags&0x40000000);stride=flags&0xfffc
  if count>256 or stride!=(12 if relative else 24):raise ValueError('Unexpected HTTP method table')
  for i in range(count):
   p=table+8+i*stride
   if relative:
    nr,tr,ir=image.at('iii',p);name=image.string(p+nr if direct else image.pointer(p+nr));encoding=image.types(p+4+tr);imp=p+8+ir
   else:name=image.string(image.pointer(p));encoding=image.types(image.pointer(p+8));imp=image.pointer(p+16)
   if name not in METHODS:continue
   end=spans.get(imp)
   if not end or not 0<end-imp<=32768:raise ValueError('Unbounded HTTP method')
   body=raw[image.offset(imp,end-imp):image.offset(imp,end-imp)+end-imp];calls=[];lines=[]
   for ins in decoder.disasm(body,imp):
    annotation=''
    if ins.mnemonic in ('bl','b') and ins.operands and ins.operands[0].type==2:
     target=ins.operands[0].imm;symbol,selector=inspect_asset_probes.import_selector(image,decoder,bindings,target)
     call={'pc':ins.address,'target':target,'selector':selector,'import':symbol if symbol in IMPORTS else None}
     calls.append(call)
     annotation=' ; '+(selector or (symbol if symbol in IMPORTS else 'unresolved-direct-call'))
    lines.append(f'{ins.address:x} {ins.mnemonic} {ins.op_str}{annotation}')
   found.append({'selector':name,'encoding':encoding,'start':imp,'end':end,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest(),'calls':calls,'assembly':'\n'.join(lines)+'\n'})
 if not {'startRequest:','connectionDidFinishLoading:','connection:didReceiveData:','connection:didFailWithError:'}<=set(x['selector'] for x in found):raise ValueError('Expected HTTP methods missing')
 private.mkdir(parents=True,exist_ok=True)
 (private/'methods.private.json').write_text(json.dumps({'prepared_engine_sha256':SOURCE_HASH,'methods':[{k:v for k,v in f.items() if k!='assembly'} for f in found]},indent=2)+'\n')
 for i,f in enumerate(found):(private/f'method-{i:02d}.private.asm').write_text(f['assembly'])
 public={'format':'od-current-foundation-transport-static-v1','prepared_engine_sha256':SOURCE_HASH,'methods':[{'selector':f['selector'],'encoding':f['encoding'],'bytes':f['bytes'],'sha256':f['sha256'],'direct_reviewed_selectors':[c['selector'] for c in f['calls'] if c['selector']],'unresolved_direct_calls':sum(c['selector'] is None and c['import'] is None for c in f['calls'])} for f in found],
 'runtime_interception_verified':False,'route_enablement_claimed':False,'original_code_executed':False,'scope':'Method bodies only; unresolved direct calls are not followed and message receiver/control-flow semantics require review.'}
 report.write_text(json.dumps(public,indent=2)+'\n');print(json.dumps(public,indent=2))

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,required=True);p.add_argument('--private',type=Path,required=True);p.add_argument('--report',type=Path,required=True);a=p.parse_args();inspect(a.source,a.private,a.report)
