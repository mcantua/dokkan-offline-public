package com.personal.offlinedokkan;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.File;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.MessageDigest;
import java.nio.ByteBuffer;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.ArrayList;
import java.util.List;
import java.util.HashSet;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Our own Offline Dokkan player UI backed by JNI/SQLite; imported sources are content only. */
public final class LocalSaveActivity extends Activity {
    private static final int PICK_MASTER=1, IMPORT_SAVE=2, EXPORT_SAVE=3, IMPORT_DEFINITION=4, EXPORT_DEFINITION=5;
    private static final long MAX_FILE=512L*1024L*1024L;
    private static final String PROFILE="local-player";
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private final List<View> controls=new ArrayList<>();
    private volatile boolean destroyed;
    private boolean busy;
    private String pendingSource;
    private String pendingDefinition;
    private volatile OfflineDatabaseDownload.Stage downloaded;
    private OfflineCore core;
    private TextView status, summary;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if(state!=null)pendingSource=state.getString("importSource");
        if(state!=null)pendingDefinition=state.getString("definition");
        LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);
        int pad=(int)(20*getResources().getDisplayMetrics().density);layout.setPadding(pad,pad,pad,pad);
        TextView title=new TextView(this);title.setText("Offline Dokkan — local player save");title.setTextSize(23);layout.addView(title);
        TextView help=new TextView(this);help.setText("Your Offline Dokkan player has one saved progression. Download or import a database as a content source, then open your player. Downloads happen only when you choose them. Imported files stay unchanged.");layout.addView(help);
        addButton(layout,"Import data source",this::chooseSource);
        addButton(layout,"Create / open local player",()->perform(()->snapshot(openCore())));
        addButton(layout,"Refresh saved state",()->perform(()->snapshot(openCore())));
        addButton(layout,"Characters",this::showCharacters);
        addButton(layout,"Teams",this::showTeam);
        addButton(layout,"Open Unit Creator",()->perform(()->{openCore();return "ready";},selected->startActivity(new Intent(this,OfflineCreatorActivity.class))));
        addButton(layout,"Export player save",()->pick(EXPORT_SAVE,true));
        addButton(layout,"Import player save",()->pick(IMPORT_SAVE,false));
        addButton(layout,"Import Offline Creator unit",()->pick(IMPORT_DEFINITION,false));
        addButton(layout,"Export Offline Creator unit",this::chooseDefinition);
        status=new TextView(this);status.setText("Import a data source, then open your player.");status.setPadding(0,pad,0,pad);layout.addView(status);
        summary=new TextView(this);summary.setTextSize(18);summary.setText("No player opened yet.");layout.addView(summary);
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.addView(layout);
        scroll.setOnApplyWindowInsetsListener((view,insets)->{view.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());return insets;});
        setContentView(scroll);scroll.requestApplyInsets();
    }
    private void addButton(LinearLayout layout,String text,Runnable action){Button b=new Button(this);b.setText(text);b.setOnClickListener(v->action.run());controls.add(b);layout.addView(b);}
    private void chooseSource(){
        if(busy)return;
        new AlertDialog.Builder(this).setTitle("Import data source")
            .setItems(new String[]{"Dokkan Eclipse source","Dokkan Sparking source"},(dialog,index)->sourceAction(index==0?"eclipse":"sparking")).setNegativeButton("Cancel",null).show();
    }
    private void sourceAction(String source){
        new AlertDialog.Builder(this).setTitle("eclipse".equals(source)?"Dokkan Eclipse data":"Dokkan Sparking data")
            .setItems(new String[]{"Download database","Import file"},(dialog,index)->{if(index==0)downloadDatabase(source);else{pendingSource=source;pick(PICK_MASTER,false);}}).setNegativeButton("Cancel",null).show();
    }
    private void downloadDatabase(String source){
        perform(()->{
            OfflineDatabaseDownload.Stage candidate=OfflineDatabaseDownload.download(this,source,()->destroyed);
            try{validateMaster(candidate.database);downloaded=candidate;return "ready";}catch(Exception|Error failure){candidate.close();throw failure;}
        },ready->{
            OfflineDatabaseDownload.Stage candidate=downloaded;if(candidate==null)return;
            new AlertDialog.Builder(this).setTitle("Database downloaded")
                .setMessage("Use this downloaded data for Offline Dokkan? Your current player will be kept if a content migration is needed.")
                .setPositiveButton("Use downloaded database",(dialog,index)->{downloaded=null;perform(()->{try(OfflineDatabaseDownload.Stage stage=candidate){return useMaster(stage.database,stage.source,stage.sha256);}});})
                .setNegativeButton("Cancel",(dialog,index)->discardDownload(candidate))
                .setOnCancelListener(dialog->discardDownload(candidate)).show();
        });
    }
    private void discardDownload(OfflineDatabaseDownload.Stage candidate){
        if(destroyed)return;if(downloaded==candidate)downloaded=null;
        worker.execute(()->{try{candidate.close();}catch(Exception error){runOnUiThread(()->{if(!destroyed)status.setText("Could not remove a temporary download. Reopen data setup before trying again.");});}});
    }
    private void pick(int code,boolean create){
        if(busy)return;
        boolean definition=code==IMPORT_DEFINITION||code==EXPORT_DEFINITION;
        Intent i=new Intent(create?Intent.ACTION_CREATE_DOCUMENT:Intent.ACTION_OPEN_DOCUMENT);i.addCategory(Intent.CATEGORY_OPENABLE);i.setType(create?(definition?"application/json":"application/x-sqlite3"):"*/*");
        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|(create?Intent.FLAG_GRANT_WRITE_URI_PERMISSION:0));
        if(create)i.putExtra(Intent.EXTRA_TITLE,definition?"OfflineDokkan-unit.json":"OfflineDokkan-save.db");
        startActivityForResult(i,code);
    }
    private interface Task {String run()throws Exception;}
    private interface Completion {void run(String result)throws Exception;}
    private void perform(Task task){perform(task,null);}
    private void perform(Task task,Completion completion){
        if(busy)return;busy=true;for(View v:controls)v.setEnabled(false);status.setText("Working…");
        worker.execute(()->{String text=null,message="Saved state ready.";try{text=task.run();}catch(Exception e){message=friendly(e.getMessage());}catch(StackOverflowError e){message="That file has unsupported nesting. Your player was kept.";}catch(LinkageError e){message="The native save engine is unavailable in this package.";}
            final String result=text,notice=message;
            runOnUiThread(()->{if(destroyed)return;busy=false;for(View v:controls)v.setEnabled(true);status.setText(notice);if(result!=null){try{if(completion!=null)completion.run(result);else summary.setText(result);}catch(Exception e){status.setText(friendly(e.getMessage()));}}});});
    }
    private OfflineCore openCore()throws Exception{
        if(core==null){OfflinePlayerStore.Selection selected=OfflinePlayerStore.active(this);if(selected==null)throw new IllegalStateException("MASTER_REQUIRED");
            OfflineCore candidate=new OfflineCore(new File(selected.directory,"player.db").getPath(),selected.master.getPath(),"sha256:"+selected.hash);
            try{candidate.execute("profile.create",PROFILE,"bootstrap-player-v1","{}");}catch(RuntimeException e){candidate.close();throw e;}
            core=candidate;
        }
        return core;
    }
    private String snapshot(OfflineCore engine)throws Exception{
        JSONObject x=new JSONObject(engine.execute("profile.refresh",PROFILE,UUID.randomUUID().toString(),"{}"));JSONArray inventory=x.getJSONArray("inventory");long stones=0;
        for(int n=0;n<inventory.length();n++){JSONObject row=inventory.getJSONObject(n);if("stone".equals(row.getString("kind"))&&row.getLong("id")==0)stones=row.getLong("quantity");}
        JSONObject created=new JSONObject(engine.execute("creator.library",PROFILE,null,"{}"));
        return "Offline Dokkan player\n\nOwned characters: "+x.getJSONArray("cards").length()+"\nCreated units: "+created.getJSONArray("definitions").length()+"\nTeams: "+x.getJSONArray("teams").length()+"\nDragon Stones: "+stones+"\nStamina: "+x.getLong("stamina")+"\nSave revision: "+x.getLong("revision");
    }
    private static void definitionNames(JSONObject player,String field,Map<String,String> names)throws Exception {
        JSONArray definitions=player.optJSONArray(field);if(definitions==null)return;
        for(int n=0;n<definitions.length();n++){
            JSONObject row=definitions.getJSONObject(n),document=row.getJSONObject("document"),card=document.getJSONObject("card");
            String name=card.optString("name","").trim();if(!name.isEmpty())names.put(row.getString("definition_id")+":"+row.getLong("version"),name);
        }
    }
    private String collection()throws Exception {
        JSONObject player=new JSONObject(openCore().execute("profile.snapshot",PROFILE,null,"{}"));JSONArray cards=player.getJSONArray("cards");
        Map<String,String> customNames=new HashMap<>();definitionNames(player,"created_definitions",customNames);definitionNames(player,"tournament_definitions",customNames);
        OfflinePlayerStore.Selection selected=OfflinePlayerStore.active(this);if(selected==null)throw new IllegalStateException("MASTER_REQUIRED");
        try(SQLiteDatabase master=SQLiteDatabase.openDatabase(selected.master.getPath(),null,SQLiteDatabase.OPEN_READONLY|SQLiteDatabase.NO_LOCALIZED_COLLATORS)){
            Map<Long,String> baseNames=new HashMap<>();
            for(int n=0;n<cards.length();n++){
                JSONObject card=cards.getJSONObject(n);String name=null;JSONObject definition=card.optJSONObject("created_definition");if(definition==null)definition=card.optJSONObject("tournament_definition");
                if(definition!=null)name=customNames.get(definition.getString("definition_id")+":"+definition.getLong("version"));
                long id=card.getLong("master_id");
                if(name==null){
                    if(!baseNames.containsKey(id)){try(Cursor rows=master.rawQuery("SELECT name FROM cards WHERE id=?",new String[]{Long.toString(id)})){baseNames.put(id,rows.moveToFirst()?rows.getString(0):"Unnamed character");}}
                    name=baseNames.get(id);
                }
                card.put("displayName",name==null||name.trim().isEmpty()?"Unnamed character":name);
            }
        }
        return player.toString();
    }
    private static String characterLabel(JSONObject card)throws Exception {
        return card.getString("displayName")+" · Lv. "+card.getLong("level")+" · Super Attack Lv. "+card.getLong("sa_level")+(card.optInt("locked",0)!=0?" · Locked":"");
    }
    private void showCharacters(){
        perform(this::collection,text->{
            JSONArray cards=new JSONObject(text).getJSONArray("cards");
            if(cards.length()==0){new AlertDialog.Builder(this).setTitle("Characters").setMessage("Your collection is empty. Finish a unit in Unit Creator to add it here.").setPositiveButton("OK",null).show();return;}
            String[] names=new String[cards.length()];for(int n=0;n<names.length;n++)names[n]=characterLabel(cards.getJSONObject(n));
            new AlertDialog.Builder(this).setTitle("Characters").setItems(names,(dialog,index)->{try{showCharacter(cards.getJSONObject(index));}catch(Exception error){status.setText("Could not open that character. Your collection was kept.");}}).setNegativeButton("Close",null).show();
        });
    }
    private void showCharacter(JSONObject card)throws Exception {
        boolean locked=card.optInt("locked",0)!=0;long instance=card.getLong("instance_id");
        new AlertDialog.Builder(this).setTitle(card.getString("displayName"))
            .setMessage("Lv. "+card.getLong("level")+"\nSuper Attack Lv. "+card.getLong("sa_level")+"\n"+(locked?"Locked":"Unlocked"))
            .setNeutralButton(locked?"Unlock":"Lock",(dialog,index)->perform(()->{OfflineCore engine=openCore();engine.execute("card.lock",PROFILE,UUID.randomUUID().toString(),new JSONObject().put("instance_id",instance).put("locked",!locked).toString());return snapshot(engine);}))
            .setPositiveButton("Close",null).show();
    }
    private void showTeam(){
        perform(this::collection,text->{
            JSONObject player=new JSONObject(text);JSONArray cards=player.getJSONArray("cards"),teams=player.getJSONArray("teams");LinkedHashSet<Long> selected=new LinkedHashSet<>();
            for(int n=0;n<teams.length();n++){JSONObject team=teams.getJSONObject(n);if(team.getInt("slot")==0){JSONArray members=team.getJSONArray("members");for(int k=0;k<members.length();k++)selected.add(members.getLong(k));}}
            if(cards.length()==0){new AlertDialog.Builder(this).setTitle("Teams").setMessage("Add a character to your collection before building a team.").setPositiveButton("OK",null).show();return;}
            String[] labels=new String[cards.length()];long[] instances=new long[cards.length()];boolean[] checked=new boolean[cards.length()];
            for(int n=0;n<cards.length();n++){JSONObject card=cards.getJSONObject(n);labels[n]=characterLabel(card);instances[n]=card.getLong("instance_id");checked[n]=selected.contains(instances[n]);}
            new AlertDialog.Builder(this).setTitle("Team 1 · first choice is leader")
                .setMultiChoiceItems(labels,checked,(dialog,index,value)->{if(value){if(selected.size()>=6){((AlertDialog)dialog).getListView().setItemChecked(index,false);Toast.makeText(this,"Choose up to 6 characters.",Toast.LENGTH_SHORT).show();return;}selected.add(instances[index]);}else selected.remove(instances[index]);})
                .setPositiveButton("Save team",(dialog,index)->saveTeam(selected))
                .setNeutralButton("Clear team",(dialog,index)->saveTeam(new LinkedHashSet<>()))
                .setNegativeButton("Cancel",null).show();
        });
    }
    private void saveTeam(LinkedHashSet<Long> selected){
        JSONArray members=new JSONArray();for(long instance:selected)members.put(instance);
        perform(()->{OfflineCore engine=openCore();engine.execute("team.set",PROFILE,UUID.randomUUID().toString(),new JSONObject().put("slot",0).put("members",members).toString());return snapshot(engine);});
    }
    private void chooseDefinition(){
        perform(()->openCore().execute("creator.library",PROFILE,null,"{}"),text->{
            JSONArray units=new JSONObject(text).getJSONArray("definitions");
            if(units.length()==0){status.setText("Import an Offline Creator unit first.");return;}
            String[] names=new String[units.length()],ids=new String[units.length()];
            for(int n=0;n<units.length();n++){JSONObject row=units.getJSONObject(n);ids[n]=row.getString("definition_id");names[n]=row.optString("name",ids[n])+" · v"+row.getLong("version");}
            new AlertDialog.Builder(this).setTitle("Choose a created unit").setItems(names,(dialog,index)->{pendingDefinition=ids[index];pick(EXPORT_DEFINITION,true);}).setNegativeButton("Cancel",null).show();
        });
    }
    private String readDefinition(Uri uri)throws Exception{
        try(InputStream in=getContentResolver().openInputStream(uri);ByteArrayOutputStream out=new ByteArrayOutputStream()){
            if(in==null)throw new IllegalStateException("FILE_UNAVAILABLE");byte[] buffer=new byte[65536];int n;
            while((n=in.read(buffer))!=-1){if(out.size()+n>16*1024*1024)throw new IllegalStateException("DEFINITION_TOO_LARGE");out.write(buffer,0,n);}
            return StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(out.toByteArray())).toString();
        }
    }
    private static long copy(InputStream in,OutputStream out,MessageDigest digest)throws Exception{
        if(in==null||out==null)throw new IllegalStateException("FILE_UNAVAILABLE");byte[] buffer=new byte[65536];long total=0;int n;
        while((n=in.read(buffer))!=-1){total+=n;if(total>MAX_FILE)throw new IllegalStateException("FILE_TOO_LARGE");out.write(buffer,0,n);if(digest!=null)digest.update(buffer,0,n);}return total;
    }
    private static String hex(byte[] bytes){StringBuilder s=new StringBuilder();for(byte b:bytes)s.append(String.format(java.util.Locale.ROOT,"%02x",b&255));return s.toString();}
    private static void validateMaster(File file)throws Exception{
        // Android's supported read-only SQLite API is used only to validate the imported file;
        // the actual native engine links our public pinned SQLite, never the private system ABI.
        try(SQLiteDatabase db=SQLiteDatabase.openDatabase(file.getPath(),null,SQLiteDatabase.OPEN_READONLY|SQLiteDatabase.NO_LOCALIZED_COLLATORS)){
            try(Cursor rows=db.rawQuery("PRAGMA quick_check",null)){if(!rows.moveToFirst()||!"ok".equals(rows.getString(0))||rows.moveToNext())throw new IllegalStateException("INVALID_MASTER");}
            HashSet<String> tables=new HashSet<>(),columns=new HashSet<>();
            try(Cursor rows=db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'",null)){while(rows.moveToNext())tables.add(rows.getString(0));}
            for(String table:new String[]{"cards","leader_skill_sets","passive_skill_sets","quests","sugoroku_maps"})if(!tables.contains(table))throw new IllegalStateException("INVALID_MASTER");
            try(Cursor rows=db.rawQuery("PRAGMA table_info(cards)",null)){while(rows.moveToNext())columns.add(rows.getString(1));}
            for(String column:new String[]{"id","name","rarity","element","hp_init","hp_max","atk_init","atk_max","def_init","def_max","lv_max","skill_lv_max","leader_skill_set_id","passive_skill_set_id"})if(!columns.contains(column))throw new IllegalStateException("INVALID_MASTER");
        }
    }
    private String importMaster(Uri uri,String source)throws Exception{
        try(OfflineMasterArchive.Stage input=OfflineMasterArchive.stage(this,uri,source)){return useMaster(input.database(),source,null);}
    }
    private String useMaster(File stage,String source,String expectedHash)throws Exception{
        if(!OfflinePlayerStore.validSource(source))throw new IllegalStateException("INVALID_CONTENT_SOURCE");
        OfflinePlayerStore.Selection current=OfflinePlayerStore.active(this);File dir=OfflinePlayerStore.directory(this);
        if(!dir.isDirectory()&&!dir.mkdirs())throw new IllegalStateException("STORAGE_UNAVAILABLE");
        File probe=new File(dir,"master-probe-"+UUID.randomUUID()+".db");MessageDigest digest=MessageDigest.getInstance("SHA-256");
        try{
            if(stage.length()>MAX_FILE)throw new IllegalStateException("FILE_TOO_LARGE");
            validateMaster(stage);
            try(InputStream in=new FileInputStream(stage)){byte[] bytes=new byte[65536];int count;while((count=in.read(bytes))!=-1)digest.update(bytes,0,count);}
            String hash=hex(digest.digest());
            if(expectedHash!=null&&!expectedHash.equals(hash))throw new IllegalStateException("SOURCE_HASH_MISMATCH");
            if(new File(dir,"player.db").exists()&&(current==null||!hash.equals(current.hash)||!source.equals(current.source)))throw new IllegalStateException("CONTENT_MIGRATION_REQUIRED");
            try(OfflineCore check=new OfflineCore(probe.getPath(),stage.getPath(),"sha256:"+hash)){check.execute("profile.create","validate-input","validate-input","{}");}
            File dest=new File(dir,"master-"+hash+".db");if(!dest.exists()&&!stage.renameTo(dest))throw new IllegalStateException("STORAGE_UNAVAILABLE");
            OfflinePlayerStore.writeReceipt(dir,source,hash);OfflinePlayerStore.activate(this,new OfflinePlayerStore.Selection(dir,source,hash));
            if(core!=null){core.close();core=null;}return snapshot(openCore());
        }finally{probe.delete();new File(probe.getPath()+"-journal").delete();}
    }
    @Override protected void onActivityResult(int code,int result,Intent data){
        super.onActivityResult(code,result,data);if(result!=RESULT_OK||data==null||data.getData()==null)return;Uri uri=data.getData();
        if(code==PICK_MASTER){final String source=pendingSource;pendingSource=null;perform(()->importMaster(uri,source));return;}
        if(code==IMPORT_DEFINITION){perform(()->{OfflineCore engine=openCore();String document=readDefinition(uri);engine.execute("creator.finish",PROFILE,UUID.randomUUID().toString(),"{\"definition\":"+document+"}");return snapshot(engine);});return;}
        if(code==EXPORT_DEFINITION){final String id=pendingDefinition;pendingDefinition=null;perform(()->{
            if(id==null)throw new IllegalStateException("DEFINITION_REQUIRED");String document=openCore().execute("creator.export",PROFILE,null,new JSONObject().put("definition_id",id).toString());
            try(OutputStream out=getContentResolver().openOutputStream(uri,"w")){if(out==null)throw new IllegalStateException("FILE_UNAVAILABLE");out.write(document.getBytes(StandardCharsets.UTF_8));}
            return snapshot(openCore());});return;}
        if(code!=IMPORT_SAVE&&code!=EXPORT_SAVE)return;
        perform(()->{OfflineCore engine=openCore();File temp=File.createTempFile("player-transfer-",".db",getCacheDir());try{
            if(code==EXPORT_SAVE){if(!temp.delete())throw new IllegalStateException("STORAGE_UNAVAILABLE");engine.exportSave(temp.getPath());try(InputStream in=new FileInputStream(temp);OutputStream out=getContentResolver().openOutputStream(uri,"w")){copy(in,out,null);}}
            else{try(InputStream in=getContentResolver().openInputStream(uri);FileOutputStream out=new FileOutputStream(temp)){copy(in,out,null);out.getFD().sync();}engine.importSave(temp.getPath());}
            return snapshot(engine);
        }finally{temp.delete();}});
    }
    private static String friendly(String code){
        if("MASTER_REQUIRED".equals(code))return "Import a data source first.";
        if("CONTENT_MIGRATION_REQUIRED".equals(code))return "This is different game data. A save migration is needed; your existing player was kept.";
        if("LEGACY_SAVE_SELECTION_REQUIRED".equals(code))return "More than one earlier development save was found. Your files were kept. A reviewed recovery choice is needed before opening your single player.";
        if("LEGACY_SAVE_RECOVERY_REQUIRED".equals(code))return "An earlier development save needs recovery before opening your player. Your files were kept.";
        if("FILE_TOO_LARGE".equals(code))return "That file is larger than the supported 512 MB.";
        if("DEFINITION_TOO_LARGE".equals(code))return "That unit file is larger than the supported 16 MB.";
        if("PLAINTEXT_MASTER_REQUIRED_NO_DECRYPTION".equals(code))return "The Sparking website returned an encrypted database. Import your own already-decrypted database or compatible archive. No decryption keys are included in this app.";
        if("SOURCE_REDIRECT_NOT_ALLOWED".equals(code))return "The database address changed. This download was stopped; import a compatible file instead.";
        if("SOURCE_DOWNLOAD_TIMEOUT".equals(code)||"SOURCE_DOWNLOAD_CANCELLED".equals(code))return "The download stopped. Your current player was kept; you can try data setup again.";
        if("SOURCE_DOWNLOAD_BUSY".equals(code))return "Finish or cancel the current database download first.";
        if("INVALID_MASTER_DOWNLOAD".equals(code)||"SOURCE_SIZE_MISMATCH".equals(code)||"SOURCE_LENGTH_INVALID".equals(code)||"SOURCE_TOO_LARGE".equals(code)||"SOURCE_ENCODING_UNSUPPORTED".equals(code)||"SOURCE_DOWNLOAD_UNAVAILABLE".equals(code)||"SOURCE_HASH_MISMATCH".equals(code))return "The website did not provide a supported complete database. Your current player was kept; import a compatible file instead.";
        if("INVALID_DEFINITION".equals(code)||"UNSUPPORTED_DEFINITION_TABLE".equals(code))return "Choose a compatible Offline Creator unit file. The current library was kept.";
        if("CARD_NOT_OWNED".equals(code))return "That character is no longer in your collection. Reopen Characters or Teams to refresh the list.";
        if("INVALID_TEAM".equals(code)||"DUPLICATE_TEAM_MEMBER".equals(code))return "Choose up to 6 different owned characters. Your previous team was kept.";
        if("OPEN_FAILED".equals(code)||"SAVE_INVALID".equals(code)||"INVALID_MASTER".equals(code))return "The database or player save is invalid or incompatible. Your current save was kept.";
        return "The file operation could not finish. Your current local player was kept.";
    }
    @Override protected void onSaveInstanceState(Bundle state){state.putString("importSource",pendingSource);state.putString("definition",pendingDefinition);super.onSaveInstanceState(state);}
    @Override protected void onResume(){super.onResume();if(status!=null&&core!=null&&!busy&&!destroyed)perform(()->snapshot(openCore()));}
    @Override protected void onDestroy(){destroyed=true;worker.execute(()->{if(downloaded!=null){try{downloaded.close();}catch(Exception ignored){}downloaded=null;}if(core!=null){core.close();core=null;}});worker.shutdown();super.onDestroy();}
}
