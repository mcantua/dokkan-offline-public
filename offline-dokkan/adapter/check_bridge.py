"""One focused JS -> Java/JNI -> C/SQLite integration scenario with synthetic master data."""
import hashlib
import json
import pathlib
import sqlite3
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parents[1]
with tempfile.TemporaryDirectory(prefix="native-bridge-", dir=ROOT / "build") as temp:
    work = pathlib.Path(temp)
    master, save, backup = (work / x for x in ("master.db", "save.db", "backup.db"))
    card = {"id": 1, "name": "Synthetic source", "rarity": 5, "element": 10,
            "hp_init": 10, "atk_init": 20, "def_init": 30, "hp_max": 1000, "atk_max": 2000, "def_max": 3000,
            "lv_max": 150, "skill_lv_max": 20, "leader_skill_set_id": 1, "passive_skill_set_id": 1}
    with sqlite3.connect(master) as db:
        db.execute("CREATE TABLE cards(" + ",".join(k + (" TEXT" if isinstance(v, str) else " INTEGER") + (" PRIMARY KEY" if k == "id" else " NOT NULL") for k, v in card.items()) + ")")
        db.execute("INSERT INTO cards VALUES(" + ",".join("?" for _ in card) + ")", list(card.values()))
        db.execute("CREATE TABLE card_awakening_routes(id INTEGER PRIMARY KEY,card_id INTEGER,awaked_card_id INTEGER,type TEXT)")
        db.execute("CREATE TABLE leader_skill_sets(id INTEGER PRIMARY KEY,name TEXT NOT NULL)")
        db.execute("INSERT INTO leader_skill_sets VALUES(1,'Leader')")
        db.execute("CREATE TABLE passive_skill_sets(id INTEGER PRIMARY KEY,name TEXT NOT NULL)")
        db.execute("INSERT INTO passive_skill_sets VALUES(1,'Passive')")
        db.execute("CREATE TABLE sugoroku_maps(id INTEGER PRIMARY KEY)")
    content = hashlib.sha256(master.read_bytes()).hexdigest()
    project = {"format": "dokkan-unit-forge", "version": 1, "key": "unit-97000001-example",
               "source": {"cardId": 1}, "patch": {"uuid": "source-definition"}, "assets": [],
               "tables": {"cards": [card]}, "cardOverrides": {"name": "Creator 🌟 unit", "atk_max": 4321}}
    source = work / "project.json"
    source.write_text(json.dumps(project))
    document = work / "definition.json"
    # The projection is the actual adapter, not a hand-written substitute definition.
    js = """
const fs=require('node:fs'), assert=require('node:assert/strict'), helper=require(process.argv[1]);
(async()=>{const p=JSON.parse(fs.readFileSync(process.argv[2])), host={contentId:process.argv[4],sourceDatabase:'eclipse',version:1,rarity:'LR'};
 const d=await helper.projectToDefinition(p,host); assert.equal(d.card.name,'Creator 🌟 unit'); assert.equal(d.card.atk_max,4321);
 for(const mutate of [p=>p.awaken={kind:'eza'},p=>p.formProjects=[{}],p=>p.assets=[{}],p=>p.tables.unknown_settings=[{id:1}]]){
  const bad=JSON.parse(JSON.stringify(p));mutate(bad);await assert.rejects(helper.projectToDefinition(bad,host));
 }
 const unchanged=JSON.parse(JSON.stringify(p));unchanged.tables.master_metadata=[{id:1}];
 await helper.projectToDefinition(unchanged,{...host,isUnchangedMasterRows:async()=>true});
 const upgrade=JSON.parse(JSON.stringify(p));upgrade.cardOverrides={};upgrade.awaken={kind:'eza',cardId:1};
 upgrade.tables.optimal_awakening_growths=Array.from({length:7},(_,i)=>({id:-i-1,step:i+1,optimal_awakening_grow_type:97000001,lv_max:150,skill_lv_max:20,leader_skill_set_id:-3,passive_skill_set_id:-4}));
 const official=await helper.projectToOfficialUpgrade(upgrade,host);assert.equal(official.card.optimal_awakening_grow_type,97000001);assert.equal(official.card.passive_skill_set_id,-4);
 assert.equal(official.format,'offline-dokkan-official-upgrade');assert.equal(official.kind,'custom_eza');assert.equal(official.definition_id,undefined);
 let called=false;await helper.applyOfficialUpgrade(async(op,profile,command,args)=>{called=true;assert.equal(op,'upgrade.apply');assert.equal(JSON.parse(args).instance_id,1);return '{}'},upgrade,host,'p','official',1);assert(called);
 upgrade.tables.optimal_awakening_growths.pop();await assert.rejects(helper.projectToOfficialUpgrade(upgrade,host));
 fs.writeFileSync(process.argv[3],JSON.stringify(d));
})().catch(e=>{console.error(e.code||e.message);process.exit(1)});
"""
    subprocess.run(["node", "-e", js, str(ROOT / "creator-project.js"), str(source), str(document), content], check=True)
    reordered = work / "reordered-definition.json"
    def reverse_objects(value):
        if isinstance(value, dict):
            return {key: reverse_objects(item) for key, item in reversed(list(value.items()))}
        if isinstance(value, list):
            return [reverse_objects(item) for item in value]
        return value
    reordered.write_text(json.dumps(reverse_objects(json.loads(document.read_text())), ensure_ascii=False))
    java = work / "BridgeScenario.java"
    java.write_text(r'''
import com.personal.offlinedokkan.OfflineCore;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
public class BridgeScenario {
 static void check(boolean x,String name){if(!x)throw new AssertionError(name);}
 static void rejected(OfflineCore c,String op,String command,String args,String expected){
  try{c.execute(op,"p",command,args);throw new AssertionError("accepted "+op);}catch(IllegalStateException e){check(e.getMessage().equals(expected),"wrong error "+e.getMessage());}
 }
 public static void main(String[] a)throws Exception{
  String doc=new String(Files.readAllBytes(Paths.get(a[4])),StandardCharsets.UTF_8);
  String reorderedDoc=new String(Files.readAllBytes(Paths.get(a[5])),StandardCharsets.UTF_8);
  try(OfflineCore c=new OfflineCore(a[0],a[1],a[2])){
   c.execute("profile.create","p","create","{}");
   rejected(c,"profile.create","injected","{\"initial_stamina\":999}","INVALID_ARGUMENT");
   rejected(c,"profile.create","empty-key","{\"\":1}","INVALID_ARGUMENT");
   rejected(c,"inventory.grant","grant","{}","UNSUPPORTED_OPERATION");
   rejected(c,"run.start","run","{}","UNSUPPORTED_OPERATION");
   rejected(c,"upgrade.policy.install","policy","{}","UNSUPPORTED_OPERATION");
   rejected(c,"tournament.exclusive.register","exclusive","{}","UNSUPPORTED_OPERATION");
   rejected(c,"schedule.rotate","forged-clock","{\"catalog_id\":\"history\",\"now_utc\":1}","INVALID_ARGUMENT");
   rejected(c,"tournament.record_run","forged-score","{\"score\":999}","INVALID_ARGUMENT");
   rejected(c,"card.sa.train","forged-training","{\"quantity\":999}","INVALID_ARGUMENT");
   rejected(c,"/resources/login",null,"{}","GAME_WIRE_UNVERIFIED");
   rejected(c,"team.set","duplicate","{\"slot\":0,\"slot\":1,\"members\":[]}","INVALID_ARGUMENT");
   String first=c.execute("creator.import","p","import","{\"definition\":"+doc+"}");
   check(first.contains("source-definition"),"persisted definition identity");
   check(c.execute("creator.import","p","import","{\"definition\":"+reorderedDoc+"}").equals(first),"cross-platform object-order command replay");
   check(c.execute("creator.import","p","reimport","{\"definition\":"+reorderedDoc+"}").contains("source-definition"),"cross-platform same-version document sharing");
   check(c.execute("creator.export","p",null,"{\"definition_id\":\"source-definition\"}").equals(doc),"full UTF-8 settings round trip");
   String owned=c.executePolicy("card.add","p","trusted-card","{\"master_id\":1}");check(owned.contains("instance_id"),"native policy reaches persisted core");
   String locked=c.execute("card.lock","p","lock-card","{\"instance_id\":1,\"locked\":true}");check(locked.contains("\"locked\":true")||locked.contains("\"locked\":1"),"client card lock reaches persisted core");
   c.executePolicy("card.add","p","trusted-teacher","{\"master_id\":1}");
   c.executePolicy("elder_kai.configure","p","kai-policy","{\"banner_id\":\"kai\",\"version\":1,\"zone\":0,\"multi_count\":2,\"pool\":[{\"master_id\":1,\"verified_elder_kai\":true,\"super_attack_levels\":1,\"weight_ppm\":1000000}]}");
   String trained=c.execute("card.sa.train","p","train-kai","{\"target_instance_id\":1,\"material_instance_ids\":[2],\"kai_banner_id\":\"kai\",\"kai_banner_version\":1}");
   check(trained.contains("\"sa_after\":2"),"actual guaranteed Kai SA training");
   check(c.execute("card.sa.train","p","train-kai","{\"kai_banner_version\":1,\"kai_banner_id\":\"kai\",\"material_instance_ids\":[2],\"target_instance_id\":1}").equals(trained),"training replay after dictionary key reordering");
   c.exportSave(a[3]);
  }
  try(OfflineCore c=new OfflineCore(a[0],a[1],a[2])){
   check(c.execute("creator.library","p",null,"{}").contains("source-definition"),"restart persistence");
   c.importSave(a[3]);
   check(c.execute("creator.export","p",null,"{\"definition_id\":\"source-definition\"}").equals(doc),"save import round trip");
   c.close();c.close();
   try{c.execute("profile.snapshot","p",null,"{}");throw new AssertionError("closed call");}catch(IllegalStateException e){check(e.getMessage().equals("CLOSED"),"closed state");}
  }
  System.out.println("PASS: Creator projection, JNI UTF-8, cross-platform settings/intent replay, native Kai feeding, persistence/save round trip, strict capability boundary and closed state");
 }
}
''')
    subprocess.run([str(REPO / "unit-creator/tools/javac"), "--release", "8", "-Xlint:-options", "-cp", str(ROOT / "build/classes"), "-d", str(work), str(java)], check=True)
    subprocess.run(["java", "-Djava.library.path=" + str(ROOT / "build"), "-cp", str(work) + ":" + str(ROOT / "build/classes"), "BridgeScenario", str(save), str(master), content, str(backup), str(document), str(reordered)], check=True)
    assert hashlib.sha256(master.read_bytes()).hexdigest() == content
    print("PASS: imported master unchanged")
