#!/usr/bin/env python3
"""Actual native Android save-manager + system Files picker on the already-owned hosted emulator."""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET
import zipfile

ROOT=pathlib.Path(__file__).resolve().parents[3]
ADB=os.environ['UC_ADB']
OUT=pathlib.Path(os.environ['UC_ANDROID_EVIDENCE'])
PACKAGE='com.personal.offlinedokkan'


def adb(*args):
    return subprocess.check_output([ADB,'-s','emulator-5554',*args])


def tree():
    adb('shell','uiautomator','dump','/sdcard/offline-native-check.xml')
    return ET.fromstring(adb('exec-out','cat','/sdcard/offline-native-check.xml'))


def matching(root,text=None,description=None):
    for node in root.iter('node'):
        if text is not None and node.get('text','').casefold()!=text.casefold():continue
        if description is not None and node.get('content-desc','').casefold()!=description.casefold():continue
        return node
    return None


def tap(node):
    if node is None:raise ValueError('Required actual native UI control is absent')
    match=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',node.get('bounds',''))
    if not match:raise ValueError('Actual native UI bounds unavailable')
    x1,y1,x2,y2=map(int,match.groups())
    if x2<=x1 or y2<=y1:raise ValueError('Actual native UI control has no visible bounds')
    adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))


def wait(predicate,label,seconds=60):
    deadline=time.monotonic()+seconds
    while time.monotonic()<deadline:
        try:
            result=predicate(tree())
            if result is not None and result is not False:return result
        except ET.ParseError:pass
        time.sleep(.5)
    raise ValueError(label+' unavailable in actual Android UI')


def screenshot(name):
    (OUT/name).write_bytes(adb('exec-out','screencap','-p'))


def scroll(down=True):
    size=re.search(r'(\d+)x(\d+)',adb('shell','wm','size').decode())
    if not size:raise ValueError('Actual Android display size unavailable')
    width,height=map(int,size.groups())
    start,end=(height*4//5,height//3) if down else (height//3,height*4//5)
    adb('shell','input','swipe',str(width//2),str(start),str(width//2),str(end),'300')


def show_summary():
    scroll()


def open_creator(phase):
    scroll(False)
    tap(wait(lambda r:matching(r,text='Open Unit Creator'),'Actual native Creator entry'))
    deadline=time.monotonic()+90
    while time.monotonic()<deadline:
        pid=adb('shell','pidof',PACKAGE).decode().strip()
        if re.fullmatch(r'[0-9]+',pid):
            socket='webview_devtools_remote_'+pid
            if '@'+socket in adb('shell','cat','/proc/net/unix').decode():
                adb('forward','tcp:9223','localabstract:'+socket)
                break
        time.sleep(.5)
    else:raise ValueError('Actual Offline Creator WebView debugger unavailable')
    try:
        subprocess.run(['node',str(pathlib.Path(__file__).with_name('creator-cloud-check.mjs')),phase],check=True)
    finally:
        adb('forward','--remove','tcp:9223')
    tap(wait(lambda r:matching(r,text='Back to local player'),'Actual native Creator return'))
    wait(lambda r:matching(r,text='Offline Dokkan — local player save'),'Return from actual Creator')


def summary(root):
    for node in root.iter('node'):
        text=node.get('text','')
        if 'Save revision:' in text:return text
    return None


def master_unchanged(digest,archive_digest):
    if adb('shell','sha256sum','/sdcard/Download/Cloud-Eclipse.zip').decode().split()[0]!=archive_digest:raise ValueError('Original selected master archive was changed')
    private='files/offline-dokkan/local-player/master-'+digest+'.db'
    if adb('shell','run-as',PACKAGE,'sha256sum',private).decode().split()[0]!=digest:raise ValueError('Imported master bytes differ or changed during Creator use')


def import_source(label,filename):
    scroll(False)
    tap(wait(lambda r:matching(r,text='Import data source'),'Data-source setup entry'))
    tap(wait(lambda r:matching(r,text=label),'Source-only import setup'))
    tap(wait(lambda r:matching(r,text='Import file'),'Explicit local-file source action'))
    current=wait(lambda r:r if any('documentsui' in n.get('package','') for n in r.iter('node')) else None,'Actual system Files picker')
    file=matching(current,text=filename)
    if file is None:
        root=matching(current,description='Show roots')
        if root is not None:tap(root)
        downloads=wait(lambda r:matching(r,text='Downloads'),'System Files Downloads root')
        tap(downloads)
        file=wait(lambda r:matching(r,text=filename),'Real supplied runtime master archive')
    tap(file)
    wait(lambda r:matching(r,text='Offline Dokkan — local player save'),'Return to our native player')


def owned_unit(root):
    return next((node for node in root.iter('node') if node.get('text','').startswith('Native Offline Creator finished · Lv. ')),None)


def characters():
    scroll(False);scroll(False)
    tap(wait(lambda r:matching(r,text='Characters'),'Actual owned collection entry'))
    wait(owned_unit,'Actual completed custom unit name/level/Super Attack in collection')
    screenshot('offline-android-characters.png')
    tap(wait(lambda r:matching(r,text='Close'),'Close actual owned collection'))


def team(create):
    scroll(False);scroll(False)
    tap(wait(lambda r:matching(r,text='Teams'),'Actual team editor entry'))
    row=wait(owned_unit,'Actual owned team choice')
    if create:
        if row.get('checked')!='true':tap(row)
        tap(wait(lambda r:matching(r,text='Save team'),'Save actual six-member-bounded team'))
    else:
        if row.get('checked')!='true':raise ValueError('Completed custom unit did not remain in the saved team after restart')
        screenshot('offline-android-team-reopened.png')
        tap(wait(lambda r:matching(r,text='Cancel'),'Close actual persisted team'))


def main():
    # The distributed APK is data-free. Only this disposable test device receives a separate fixture file.
    source=ROOT/'unit-creator/apk/assets/reference.db'
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    # Exercise the actual new archive picker path in the same native integration
    # check. Keep the private fixture outside uploaded evidence and remove it.
    with tempfile.TemporaryDirectory(prefix='offline-native-master-') as stage:
        archive=pathlib.Path(stage)/'Cloud-Eclipse.zip'
        with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1) as container:
            container.write(source,'assets/reference.db')
        archive_digest=hashlib.sha256(archive.read_bytes()).hexdigest()
        adb('push',str(archive),'/sdcard/Download/Cloud-Eclipse.zip')
        other=pathlib.Path(stage)/'Cloud-Sparking.zip'
        with zipfile.ZipFile(other,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1) as container:
            container.write(ROOT/'unit-creator/apk/assets/sparking-reference.db','assets/sparking-reference.db')
        adb('push',str(other),'/sdcard/Download/Cloud-Sparking.zip')
    adb('shell','am','start','-W','-n',PACKAGE+'/.LocalSaveActivity')
    wait(lambda r:matching(r,text='Import data source'),'Data-free host import screen')
    if any(n.get('class','')=='android.widget.Spinner' for n in tree().iter('node')):raise ValueError('Sources must not appear as selectable player/game modes')
    screenshot('offline-android-import-screen.png')
    import_source('Dokkan Eclipse source','Cloud-Eclipse.zip')
    show_summary()
    initial=wait(summary,'Actual JNI/SQLite player snapshot',90)
    if 'Dragon Stones: 0' not in initial:raise ValueError('Fresh player must not invent rewards')
    screenshot('offline-android-player.png')
    open_creator('finish')
    show_summary()
    wait(lambda r:(text if 'Created units: 1' in text and 'Owned characters: 1' in text else None) if (text:=summary(r)) else None,'Finished unit available in actual player collection',90)
    characters();team(True);show_summary()
    first=wait(lambda r:(text if 'Teams: 1' in text else None) if (text:=summary(r)) else None,'Actual saved custom-unit team',90)
    master_unchanged(digest,archive_digest)
    import_source('Dokkan Sparking source','Cloud-Sparking.zip')
    wait(lambda r:next((n for n in r.iter('node') if 'save migration is needed' in n.get('text','')),None),'Incompatible-source refusal',90)
    show_summary()
    if wait(summary,'Preserved single player')!=first:raise ValueError('Importing a different source replaced player progression')
    private_saves=adb('shell','run-as',PACKAGE,'find','files/offline-dokkan','-name','player.db').decode().splitlines()
    if private_saves!=['files/offline-dokkan/local-player/player.db']:raise ValueError('Source import created parallel player saves')
    adb('shell','am','force-stop',PACKAGE)
    adb('shell','am','start','-W','-n',PACKAGE+'/.LocalSaveActivity')
    tap(wait(lambda r:matching(r,text='Create / open local player'),'Reopen native player'))
    show_summary()
    reopened=wait(summary,'Persisted actual native player',90)
    if reopened!=first:raise ValueError('Actual persisted native player differs after restart')
    screenshot('offline-android-reopened.png')
    team(False)
    open_creator('reopen')
    master_unchanged(digest,archive_digest)
    report={'scope':'Our original Offline Dokkan player on hosted Android; source-only ZIP import, actual Java/JNI/C Creator finish, owned collection/team, one preserved player and reopen','version':'0.1.0','code':1,'package':PACKAGE,'contains_game_data_in_apk':False,'actual_files_picker_import':True,'actual_plaintext_archive_import':True,'selected_master_fixture_sha256':digest,'actual_embedded_creator_finish_and_reopen':True,'actual_owned_character_list':True,'actual_team_saved_and_reopened':True,'actual_native_player_reopened':True,'selected_source_unchanged':True,'single_original_game_profile':True,'incompatible_source_preserves_player':True,'source_mode_picker_absent':True,'not_verified':['Physical device/folding/keyboard','Playable battles and finished game screens','Other Android API versions','Full feature parity']}
    (OUT/'offline-android-native-result.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Actual Offline Android source import/Creator/single-player persistence passed; playable battles remain unfinished.')


if __name__=='__main__':main()
