#!/usr/bin/env python3
"""Find bounded original battle literal-reference candidates; admit no DTOs.

Only exact reviewed field/path vocabulary is emitted publicly. Coordinates and
selected-function queues remain in ignored private output. A literal reference
is not proof of a request, method, schema, required field or runtime behavior.
"""
import argparse
import bisect
import hashlib
import json
from pathlib import Path
import struct
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
sys.path.insert(0,str(ROOT/'offline-dokkan/tools'))
from objc_runtime_metadata import Image
sys.path.insert(0,str(HERE.parents[1]/'protocol-inspection'))
from inspect_handler_fields import function_starts, sections_and_symbols
SHA='efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222'
VOCABULARY=('sugoroku_maps/start','sugoroku_maps/finish','quest_started_at_ms',
 'is_defeated_boss','has_player_been_taken_damage')


def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--source',type=Path,required=True)
 p.add_argument('--private-output',type=Path,required=True)
 p.add_argument('--report',type=Path,required=True)
 p.add_argument('--callers-from',type=Path,
  help='Continue only exact retained route-constructor identities to direct callers.')
 a=p.parse_args()
 if 'private' not in a.private_output.parts:raise ValueError('Private coordinates required')
 raw=a.source.read_bytes()
 if len(raw)!=55697728 or hashlib.sha256(raw).hexdigest()!=SHA:raise ValueError('Source identity mismatch')
 image=Image(raw);starts=function_starts(image);sections,_,_=sections_and_symbols(image)
 text,size,_,_=sections[b'__text'];offset=image.offset(text,size)
 ends=dict(zip(starts,starts[1:]+[text+size]))
 if a.callers_from:
  prior=json.loads(a.callers_from.read_text())
  if prior.get('source_sha256')!=SHA:raise ValueError('Caller frontier source changed')
  targets={}
  for entry in prior['body_spans']:
   routes=sorted({r['literal'] for r in entry.get('references',[]) if r['literal'].startswith('sugoroku_maps/')} |
    {suffix for c in entry.get('constructor_calls',[]) for suffix in c['route_suffixes']})
   if not routes:continue
   start,end=entry['start'],entry['end'];pos=image.offset(start,end-start)
   if ends.get(start)!=end or hashlib.sha256(raw[pos:pos+end-start]).hexdigest()!=entry['sha256']:
    raise ValueError('Constructor identity changed')
   targets[start]=routes
  if len(targets)!=2:raise ValueError('Expected two exact retained route-related targets')
  selected={}
  for relative in range(0,size-3,4):
   word=struct.unpack_from('<I',raw,offset+relative)[0]
   if word&0x7c000000!=0x14000000:continue
   immediate=word&0x3ffffff
   if immediate&0x2000000:immediate-=0x4000000
   pc=text+relative;target=pc+immediate*4
   if target not in targets:continue
   index=bisect.bisect_right(starts,pc)-1
   if index<0:continue
   start=starts[index];end=ends[start]
   if not text<=start<=pc<end<=text+size or end-start>16384:continue
   pos=image.offset(start,end-start)
   entry=selected.setdefault(start,dict(start=start,end=end,bytes=end-start,
    sha256=hashlib.sha256(raw[pos:pos+end-start]).hexdigest(),constructor_calls=[]))
   entry['constructor_calls'].append(dict(private_instruction=pc,private_target=target,
    route_suffixes=targets[target]))
  if not 1<=len(selected)<=16:raise ValueError('Caller frontier size rejected')
  a.private_output.parent.mkdir(parents=True,exist_ok=True)
  a.private_output.write_text(json.dumps(dict(source_sha256=SHA,body_spans=list(selected.values())),indent=2)+'\n')
  a.report.write_text(json.dumps(dict(kind='original-battle-exact-route-related-caller-frontier',
   source_sha256=SHA,caller_bodies=[dict(bytes=e['bytes'],sha256=e['sha256'],
    route_suffixes=sorted({s for c in e['constructor_calls'] for s in c['route_suffixes']})) for e in selected.values()],
   request_response_contract_verified=False,route_enabled=False,gameplay_verified=False,
   limitations=['Only direct B/BL callers of the two exact retained route-related targets; no indirect-call completeness claim.',
    'A call site does not establish callback payload types or response requiredness.']),indent=2)+'\n')
  print(json.dumps(dict(caller_bodies=len(selected),contract_admitted=False,game_execution=False)))
  return
 literals={}
 for name in VOCABULARY:
  needle=name.encode()+b'\0';pos=0;matches=[]
  while True:
   pos=raw.find(needle,pos)
   if pos<0:break
   # Path vocabulary is a reviewed suffix; retain its full literal's
   # coordinate privately without emitting an unknown format prefix.
   literal_start=pos
   if name.startswith('sugoroku_maps/'):
    literal_start=raw.rfind(b'\0',max(0,pos-128),pos)+1
    if literal_start==0 or pos-literal_start>128:raise ValueError('Path prefix bound exceeded')
   if literal_start==pos and pos and raw[pos-1]!=0:
    pos+=len(needle);continue
   for vm,_,off,n in image.segments:
    if off<=literal_start<off+n:matches.append(vm+literal_start-off)
   pos+=len(needle)
  if len(matches)>8:raise ValueError('Literal multiplicity exceeds bounded scope')
  for address in matches:literals[address]=name
 pages={x&~4095 for x in literals};candidates={}
 for relative in range(0,size-3,4):
  word=struct.unpack_from('<I',raw,offset+relative)[0]
  if word&0x9f000000!=0x90000000:continue
  immediate=((word>>29)&3)|(((word>>5)&0x7ffff)<<2)
  if immediate&0x100000:immediate-=0x200000
  page=((text+relative)&~4095)+(immediate<<12)
  if page not in pages:continue
  register=word&31
  for delta in range(4,29,4):
   if relative+delta+4>size:break
   nxt=struct.unpack_from('<I',raw,offset+relative+delta)[0]
   if nxt&0xff800000==0x91000000 and (nxt>>5)&31==register:
    target=page+(((nxt>>10)&4095)<<(12 if nxt&(1<<22) else 0))
    if target in literals:
     pc=text+relative;index=bisect.bisect_right(starts,pc)-1
     if index<0:continue
     start=starts[index];end=ends[start]
     if not text<=start<=pc<end<=text+size or end-start>16384:continue
     body=raw[image.offset(start,end-start):image.offset(start,end-start)+end-start]
     item=candidates.setdefault(start,dict(start=start,end=end,bytes=end-start,
       sha256=hashlib.sha256(body).hexdigest(),references=[]))
     item['references'].append(dict(instruction=pc,literal=literals[target],address=target))
   # Stop if ADRP's destination is overwritten before a matching ADD.
   if (nxt&31)==register and nxt&0xff800000!=0x91000000:break
 if len(candidates)>32:raise ValueError('Candidate-body bound exceeded')
 private=dict(source_sha256=SHA,body_spans=list(candidates.values()))
 public=dict(kind='original-battle-literal-reference-frontier',source_sha256=SHA,
  reviewed_vocabulary=list(VOCABULARY),candidate_bodies=[dict(bytes=x['bytes'],sha256=x['sha256'],
  referenced_literals=sorted({r['literal'] for r in x['references']})) for x in candidates.values()],
  request_response_contract_verified=False,route_enabled=False,gameplay_verified=False,
  limitations=['Exact field literals and reviewed route-suffix literal starts via ADRP/ADD only; indirect references and other instruction sequences are not covered.',
   'A literal reference cannot establish an endpoint, request method, DTO, requiredness or runnable battle.'])
 a.private_output.parent.mkdir(parents=True,exist_ok=True);a.report.parent.mkdir(parents=True,exist_ok=True)
 a.private_output.write_text(json.dumps(private,indent=2)+'\n');a.report.write_text(json.dumps(public,indent=2)+'\n')
 print(json.dumps(dict(candidate_bodies=len(candidates),contract_admitted=False,game_execution=False)))

if __name__=='__main__':main()
