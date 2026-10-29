#!/usr/bin/env python3
"""Restore original private DBs into the checked genuine-SDK bootstrap; never recompile or alter SDK marks."""
import argparse
import hashlib
import json
import os
import pathlib
import plistlib
import sqlite3
import stat
import subprocess
import tempfile
import zipfile

ROOT=pathlib.Path(__file__).resolve().parents[2]
W=ROOT/'unit-creator'


def digest(file):
    with file.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bootstrap',type=pathlib.Path)
    parser.add_argument('report',type=pathlib.Path)
    args=parser.parse_args();report=json.loads(args.report.read_text())
    if digest(args.bootstrap)!=report['sha256'] or report.get('actual_sdk')!='iPhoneOS27.1' or report.get('version')!='2.36.3' or report.get('build')!='128':raise ValueError('Unexpected or changed genuine device bootstrap')
    for name,sha in report['native_source_sha256'].items():
        if pathlib.PurePosixPath(name).name!=name or digest(W/'ios-objc'/name)!=sha:raise ValueError('Current native source differs; previous IPA preserved')
    originals={}
    for name in ['reference.db','sparking-reference.db']:
        database=W/'web/ios-db'/name
        con=sqlite3.connect('file:'+str(database.resolve())+'?mode=ro',uri=True)
        try:
            if con.execute('PRAGMA quick_check').fetchall()!=[('ok',)]:raise ValueError('Original database integrity failed')
            count=con.execute('SELECT count(*) FROM cards').fetchone()[0]
            if count<1000:raise ValueError('Original database is incomplete')
        finally:con.close()
        originals[name]={'sha256':digest(database),'bytes':database.stat().st_size,'cards':count}
    out=W/'out';out.mkdir(exist_ok=True);os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix='.genuine-ipa-',dir=out) as temp:
        temp=pathlib.Path(temp);candidate=temp/'UnitCreator-2.36.3.ipa'
        with zipfile.ZipFile(args.bootstrap) as source:
            if len(source.infolist())>16384 or sum(x.file_size for x in source.infolist())>512*1024*1024 or any(x.file_size>128*1024*1024 for x in source.infolist()):raise ValueError('Oversized device bootstrap rejected')
            if source.testzip():raise ValueError('Genuine bootstrap CRC failed')
            seen=set()
            for entry in source.infolist():
                path=pathlib.PurePosixPath(entry.filename)
                if path.is_absolute() or '..' in path.parts or path.parts[:2]!=('Payload','App.app') or entry.filename in seen or stat.S_ISLNK(entry.external_attr>>16):raise ValueError('Unsafe/unexpected bootstrap archive entry')
                seen.add(entry.filename)
                if entry.is_dir():continue
                rel='/'.join(path.parts[2:])
                if rel.startswith('db/') or rel=='cloud-data-provenance.json' or report['files'].get(rel)!=hashlib.sha256(source.read(entry)).hexdigest():raise ValueError('Unexpected or modified bootstrap component')
                if rel.startswith('site/'):
                    local=W/'web/site-ios'/rel[5:]
                    if not local.is_file() or digest(local)!=report['files'][rel]:raise ValueError('Current native site differs from tested cloud source; previous IPA preserved')
            if set(report['files'])!={str(pathlib.PurePosixPath(n).relative_to('Payload/App.app')) for n in seen if not n.endswith('/')}:raise ValueError('Missing bootstrap components')
            info=plistlib.loads(source.read('Payload/App.app/Info.plist'))
            if info.get('CFBundleIdentifier')!='com.dokkanunitcreator.ios' or info.get('CFBundleExecutable')!='App' or info.get('CFBundleShortVersionString')!='2.36.3' or info.get('CFBundleVersion')!='128' or info.get('DTSDKName')!='iphoneos27.1':raise ValueError('Genuine app identity mismatch')
            with zipfile.ZipFile(candidate,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as complete:
                for entry in source.infolist():complete.writestr(entry,source.read(entry))
                for name in originals:complete.write(W/'web/ios-db'/name,'Payload/App.app/db/'+name)
        with zipfile.ZipFile(candidate) as complete:
            if complete.testzip():raise ValueError('Complete IPA CRC failed')
            for name,meta in originals.items():
                with complete.open('Payload/App.app/db/'+name) as f:
                    if hashlib.file_digest(f,'sha256').hexdigest()!=meta['sha256']:raise ValueError('Original DB bytes were not preserved')
        subprocess.run(['bash',str(W/'ios-objc/check-duo.sh'),str(candidate)],check=True)
        evidence={'artifact':'unit-creator/out/UnitCreator-2.36.3.ipa','version':'2.36.3','build':'128','sha256':digest(candidate),'bytes':candidate.stat().st_size,'actual_compile_sdk':'iPhoneOS27.1','source_commit':report.get('source_commit'),'native_bootstrap_sha256':report['sha256'],'original_databases':originals,'apple_identity_signed':False,'physical_install_verified':False,'verified':['Authentic checked bootstrap hashes/current source/site','Actual device Mach-O iOS2/SDK27.1 (not simulator)','Original private database byte hashes/counts/integrity','ZIP CRC and Duo static gates'],'pending':['Apple provisioning/signing','Actual device launch/folding/touch/keyboard']}
        candidate.replace(out/'UnitCreator-2.36.3.ipa')
        metadata=out/'genuine-ios-check.json';part=metadata.with_suffix('.part');part.write_text(json.dumps(evidence,indent=2)+'\n');part.replace(metadata)
        print('Promoted genuine SDK27.1 IPA with unchanged original local DB bytes; Apple signing still required.')


if __name__=='__main__':main()
