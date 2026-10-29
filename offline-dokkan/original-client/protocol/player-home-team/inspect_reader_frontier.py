#!/usr/bin/env python3
"""Selected original player/team reader frontier; no app execution or values.

Reuses the existing bounded symbolic inspector on exact previously recovered
caller spans. It never performs a new whole-image caller/literal sweep.
Detailed addresses and events stay in the ignored private output.
"""
import argparse
import json
from pathlib import Path
import sys
from types import SimpleNamespace

HERE=Path(__file__).resolve().parent
INSPECT=HERE.parent.parent/'protocol-inspection'
sys.path.insert(0,str(INSPECT))
import trace_tutorial_state as bounded

FIELDS=frozenset(('user','cards','teams','user_card_teams','selected_team_num','selected_kobetu_team_num',
 'user_card_ids','num','name','team_bgm_filename','id','card_id','exp','skill_lv','rank','act','act_max',
 'zeni','stone','gasha_point','friends_capacity','support_leaders','tutorial','progress','contents_lv',
 'is_finished','card_capacity','total_card_capacity','support_item_capacity','is_support_item_capacity_extended',
 'referenced_sugoroku_map_id','referenced_z_battle_stage_id','referenced_card_ids','sugoroku_map_id','z_battle_stage_id','origin_battle_id','timewarp'))
CALLER_PINS={
 'profile_direct_caller_4':'8b541923621d6330cf64149520d29798b7282fa332168c54a560372340e60800',
 'profile_direct_caller_5':'c9c7c7e178f14787f392fd7f14c72f6261a6dfb3c83004a4737197f523e4a521',
 'profile_direct_caller_7':'8807a25ccd498aedb8c0456f6ac460762a2021af44274afba0da3afc6242cbc1'}

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--source',type=Path,required=True);ap.add_argument('--capstone-runtime',type=Path,required=True)
 ap.add_argument('--prior-summary',type=Path);ap.add_argument('--private-frontier',type=Path)
 ap.add_argument('--private-output',type=Path,required=True);ap.add_argument('--report',type=Path,required=True)
 args=ap.parse_args()
 if bool(args.prior_summary)==bool(args.private_frontier):raise ValueError('Choose one exact prior frontier')
 if 'private' not in args.private_output.parts:raise ValueError('Detailed output must remain private')
 args.private_output.parent.mkdir(parents=True,exist_ok=True);args.report.parent.mkdir(parents=True,exist_ok=True)
 if args.prior_summary:
  prior=json.loads(args.prior_summary.read_text())
  if prior.get('source_sha256')!=bounded.PREPARED_SHA:raise ValueError('Prior source changed')
  summaries={item['role']:item for item in prior['symbolic_summaries']}
  selected=[]
  for span in prior['reader_spans']:
   role=span['role'];summary=summaries.get(role,{})
   if role not in CALLER_PINS:continue
   if summary.get('sha256')!=CALLER_PINS[role]:raise ValueError('Selected body changed')
   selected.append({'start':span['start'],'end':span['end'],'sha256':summary['sha256']})
  if len(selected)!=len(CALLER_PINS):raise ValueError('Missing selected body')
  frontier=args.private_output.with_name('selected-frontier.private.json')
  frontier.write_text(json.dumps({'source_sha256':bounded.PREPARED_SHA,'body_spans':selected},indent=2)+'\n')
 else:frontier=args.private_frontier
 bounded.FIELDS=FIELDS
 bounded.analyze(SimpleNamespace(source=args.source,capstone_runtime=args.capstone_runtime,private_output=args.private_output,
  report=args.report,frontier_from=frontier,continue_from=None,loaders_from=None))
 report=json.loads(args.report.read_text())
 report['kind']='actual-current-player-team-selected-reader-frontier'
 report['scope']='Exact previously recovered original reader/caller spans with reviewed player/team field vocabulary only'
 report['full_http_envelope_verified']=False;report['home_team_route_admitted']=False
 report['ordinary_player_or_team_runtime_verified']=False
 report['limits'].append('Field references and partial symbolic calls do not establish complete request/response DTOs, requiredness or current method/path.')
 args.report.write_text(json.dumps(report,indent=2)+'\n')
 print('Selected player/team frontier retained; no payload, default, route or runtime admission.')

if __name__=='__main__':main()
