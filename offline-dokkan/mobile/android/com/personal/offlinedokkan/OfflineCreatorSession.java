package com.personal.offlinedokkan;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteDoneException;
import android.database.sqlite.SQLiteStatement;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.File;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/** Private own-app Creator workspace. All methods run on one native worker, never arbitrary SQL/paths. */
public final class OfflineCreatorSession implements AutoCloseable {
    private static final long SAFE=9007199254740991L;
    private static final int PROJECT_LIMIT=20*1024*1024, DEFINITION_LIMIT=16*1024*1024, HISTORY_LIMIT=40*1024*1024;
    private final SQLiteDatabase master,workspace;
    private final OfflineCore core;
    private final String game,content,profile;
    private final File battleDirectory;
    private OfflineBattleStore battleStore;
    interface BattleDispatcher {void dispatch(String operation,JSONObject args,boolean page,OfflineBattleCoordinator.Reply reply)throws Exception;}
    private BattleDispatcher battleDispatcher;
    private final Map<String,Set<String>> schema=new HashMap<>();
    private final JSONObject schemaJSON=new JSONObject();
    private final Set<String> projectionTables=new HashSet<>();

    public OfflineCreatorSession(File masterFile,File workspaceFile,OfflineCore engine,String selectedGame,
                                 String pinnedContent,String owner,JSONArray allowedTables)throws Exception {
        if(!Arrays.asList("eclipse","sparking").contains(selectedGame)||!pinnedContent.matches("sha256:[a-f0-9]{64}"))throw failure("INVALID_HOST_CONTEXT");
        game=selectedGame;content=pinnedContent;profile=owner;core=engine;
        battleDirectory=workspaceFile.getParentFile();
        master=SQLiteDatabase.openDatabase(masterFile.getPath(),null,SQLiteDatabase.OPEN_READONLY|SQLiteDatabase.NO_LOCALIZED_COLLATORS);
        try{workspace=SQLiteDatabase.openOrCreateDatabase(workspaceFile,null);}catch(RuntimeException error){master.close();throw error;}
        try{
        workspace.execSQL("PRAGMA foreign_keys=ON");
        workspace.disableWriteAheadLogging();
        try(Cursor mode=workspace.rawQuery("PRAGMA journal_mode=DELETE",null)){if(!mode.moveToFirst()||!"delete".equalsIgnoreCase(mode.getString(0)))throw failure("CREATOR_STORAGE_UNAVAILABLE");}
        workspace.execSQL("PRAGMA synchronous=FULL");
        workspace.execSQL("CREATE TABLE IF NOT EXISTS projects(key TEXT PRIMARY KEY,json TEXT NOT NULL,revision TEXT NOT NULL,updated TEXT NOT NULL)");
        workspace.execSQL("CREATE TABLE IF NOT EXISTS versions(version_key TEXT PRIMARY KEY,project_key TEXT NOT NULL,label TEXT NOT NULL,created TEXT NOT NULL,json TEXT NOT NULL,safety INTEGER NOT NULL DEFAULT 0)");
        workspace.execSQL("CREATE TABLE IF NOT EXISTS intents(project_key TEXT PRIMARY KEY,snapshot TEXT NOT NULL,revision TEXT NOT NULL,context TEXT NOT NULL,command TEXT NOT NULL,definition TEXT,completed INTEGER NOT NULL DEFAULT 0)");
        workspace.execSQL("CREATE TABLE IF NOT EXISTS preferences(id INTEGER PRIMARY KEY,json TEXT NOT NULL)");
        for(int n=0;n<allowedTables.length();n++)projectionTables.add(allowedTables.getString(n));
        try(Cursor tables=master.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",null)){
            while(tables.moveToNext()){
                String name=tables.getString(0);if(!identifier(name))continue;
                JSONArray columns=new JSONArray();Set<String> names=new HashSet<>();
                try(Cursor rows=master.rawQuery("PRAGMA table_info(\""+name+"\")",null)){
                    while(rows.moveToNext()){JSONObject row=cursorObject(rows);columns.put(row);names.add(row.getString("name"));}
                }
                schema.put(name,names);schemaJSON.put(name,columns);
            }
        }
        }catch(Exception|Error error){workspace.close();master.close();throw error;}
    }
    private static IllegalStateException failure(String code){return new IllegalStateException(code);}
    private static boolean identifier(String name){return name!=null&&name.matches("[a-z][a-z0-9_]*");}
    private static String key(JSONObject args)throws Exception {String key=args.getString("key");if(!key.matches("[A-Za-z0-9_.:-]{1,160}"))throw failure("INVALID_PROJECT_KEY");return key;}
    private static void only(JSONObject args,String... permitted)throws Exception {
        Set<String> fields=new HashSet<>(Arrays.asList(permitted));Iterator<String> names=args.keys();
        while(names.hasNext())if(!fields.contains(names.next()))throw failure("UNSUPPORTED_CREATOR_ARGUMENT");
    }
    private static long integer(Object value,long minimum,long maximum){
        if(!(value instanceof Number))throw failure("INVALID_INTEGER");double number=((Number)value).doubleValue();
        if(!Double.isFinite(number)||number!=Math.rint(number)||number<minimum||number>maximum)throw failure("INVALID_INTEGER");return ((Number)value).longValue();
    }
    private static String hash(String text)throws Exception {
        byte[] digest=MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8));StringBuilder result=new StringBuilder();
        for(byte item:digest)result.append(String.format(java.util.Locale.ROOT,"%02x",item&255));return result.toString();
    }
    private static String jsonText(JSONObject value)throws Exception {String text=value.toString();if(text.getBytes(StandardCharsets.UTF_8).length>PROJECT_LIMIT)throw failure("CREATOR_PROJECT_TOO_LARGE");return text;}
    private static Object cell(Cursor cursor,int column)throws Exception {
        switch(cursor.getType(column)){
            case Cursor.FIELD_TYPE_NULL:return JSONObject.NULL;
            case Cursor.FIELD_TYPE_INTEGER:return cursor.getLong(column);
            case Cursor.FIELD_TYPE_FLOAT:return cursor.getDouble(column);
            case Cursor.FIELD_TYPE_STRING:return cursor.getString(column);
            default:throw failure("UNSUPPORTED_BINARY_MASTER_COLUMN");
        }
    }
    private static JSONObject cursorObject(Cursor cursor)throws Exception {JSONObject result=new JSONObject();for(int n=0;n<cursor.getColumnCount();n++)result.put(cursor.getColumnName(n),cell(cursor,n));return result;}
    private static boolean same(Object left,Object right)throws Exception {
        if(left==JSONObject.NULL||left==null)return right==JSONObject.NULL||right==null;
        if(left instanceof JSONObject&&right instanceof JSONObject){JSONObject a=(JSONObject)left,b=(JSONObject)right;if(a.length()!=b.length())return false;Iterator<String> keys=a.keys();while(keys.hasNext()){String key=keys.next();if(!b.has(key)||!same(a.get(key),b.get(key)))return false;}return true;}
        if(left instanceof JSONArray&&right instanceof JSONArray){JSONArray a=(JSONArray)left,b=(JSONArray)right;if(a.length()!=b.length())return false;for(int n=0;n<a.length();n++)if(!same(a.get(n),b.get(n)))return false;return true;}
        if(left instanceof Number&&right instanceof Number)return new BigDecimal(left.toString()).compareTo(new BigDecimal(right.toString()))==0;
        return left.getClass()==right.getClass()&&left.equals(right);
    }
    private void column(String table,String name){if(!identifier(name)||!schema.containsKey(table)||!schema.get(table).contains(name))throw failure("UNKNOWN_MASTER_COLUMN");}
    public Object call(String operation,JSONObject args)throws Exception {
        if(args==null)args=new JSONObject();
        switch(operation){
            case "info":only(args);return new JSONObject().put("schema",schemaJSON).put("count",countCards()).put("meta",new JSONObject().put("source",game+" user-imported database").put("date",content)).put("database",new JSONObject().put("canRestore",false)).put("offlineCreator",new JSONObject().put("sourceDatabase",game).put("contentId",content));
            case "query":return query(args);
            case "querySparking":if(!game.equals("sparking"))throw failure("SOURCE_DATABASE_UNAVAILABLE");return query(args);
            case "sparkingInfo":only(args);return new JSONObject().put("available",game.equals("sparking")).put("schema",game.equals("sparking")?schemaJSON:new JSONObject()).put("snapshotId",game.equals("sparking")?content:JSONObject.NULL).put("keyConfigured",false);
            case "cardIndex":only(args);return cardIndex();
            case "projects":only(args);return projects();
            case "loadProject":only(args,"key");return new JSONObject(projectText(key(args)));
            case "saveProject":only(args,"project");return saveProject(args.getJSONObject("project"));
            case "deleteProject":only(args,"key");return deleteProject(key(args));
            case "listProjectVersions":only(args,"key");return versions(key(args));
            case "saveProjectVersion":only(args,"key","label","expectedCurrentRevision");return saveVersion(args);
            case "loadProjectVersion":only(args,"key","versionKey");return versionProject(key(args),args.getString("versionKey"));
            case "restoreProjectVersion":only(args,"key","versionKey","expectedCurrentRevision");return restoreVersion(args);
            case "deleteProjectVersion":only(args,"key","versionKey");workspace.delete("versions","project_key=? AND version_key=?",new String[]{key(args),args.getString("versionKey")});return versions(key(args));
            case "patches":case "assets":only(args,"query","offset","limit");return new JSONArray();
            case "settings":only(args);return settings();
            case "settingsSave":return saveSettings(args);
            case "offlineCreatorPrepare":only(args,"key");return prepare(key(args));
            case "offlineCreatorFinish":only(args,"key","snapshot","definition");return finish(key(args),args.getString("snapshot"),args.getJSONObject("definition"));
            case "offlineGameSnapshot":only(args);return new JSONObject(core.execute("profile.refresh",profile,java.util.UUID.randomUUID().toString(),"{}"));
            case "offlineCardStats":only(args,"instanceId");return new JSONObject(core.execute("card.stats",profile,null,new JSONObject().put("instance_id",integer(args.get("instanceId"),1,SAFE)).toString()));
            case "offlineTeamSet":return gameTeam(args);
            default:throw failure("UNSUPPORTED_OFFLINE_CREATOR_OPERATION");
        }
    }
    private JSONObject gameTeam(JSONObject args)throws Exception {
        only(args,"slot","members","intentId");long slot=integer(args.get("slot"),0,19);JSONArray members=args.getJSONArray("members");
        if(members.length()>6||!(args.get("intentId") instanceof String))throw failure("INVALID_TEAM");String intent=args.getString("intentId");
        if(!intent.matches("[A-Za-z0-9_.:-]{1,100}"))throw failure("INVALID_GAME_INTENT");
        Set<Long> selected=new HashSet<>();JSONArray trustedMembers=new JSONArray();
        for(int n=0;n<members.length();n++){long id=integer(members.get(n),1,SAFE);if(!selected.add(id))throw failure("DUPLICATE_TEAM_MEMBER");trustedMembers.put(id);}
        core.execute("team.set",profile,"game-team:"+intent,new JSONObject().put("slot",slot).put("members",trustedMembers).toString());
        return new JSONObject(core.execute("profile.snapshot",profile,null,"{}"));
    }
    /** Native-owned isolated coordinator only; intentionally absent from call()/postMessage. */
    Object nativeBattleOperation(String operation,JSONObject args)throws Exception {
        if(args==null)args=new JSONObject();
        if(!operation.equals("offlineBattleRead")&&!operation.equals("offlineBattleCompareSwap"))throw failure("UNSUPPORTED_NATIVE_BATTLE_OPERATION");
        if(battleStore==null)battleStore=new OfflineBattleStore(battleDirectory,game,content,profile);
        if(operation.equals("offlineBattleRead")){only(args);return battleStore.read();}
        only(args,"expectedToken","data");Object expected=args.get("expectedToken"),data=args.get("data");
        if(expected!=JSONObject.NULL&&!(expected instanceof String)||!(data instanceof String))throw failure("BATTLE_STORAGE_RECORD_INVALID");
        return battleStore.compareAndSwap(expected==JSONObject.NULL?null:(String)expected,(String)data);
    }
    void attachBattleDispatcher(BattleDispatcher dispatcher){battleDispatcher=dispatcher;}
    /** Page calls forward asynchronously so native RPC can use this same worker without deadlock. */
    boolean forwardPublicBattle(String operation,JSONObject args,OfflineBattleCoordinator.Reply reply)throws Exception {
        String engine;
        if(operation.equals("offlineBattleLoad")){only(args);engine="load";}
        else if(operation.equals("offlineBattleDispatch")){only(args,"command");args.getJSONObject("command");engine="dispatch";}
        else return false;
        if(args.toString().getBytes(StandardCharsets.UTF_8).length>65536)throw failure("BATTLE_REQUEST_TOO_LARGE");
        if(battleDispatcher==null)throw failure("BATTLE_ENGINE_UNAVAILABLE");battleDispatcher.dispatch(engine,args,true,reply);return true;
    }
    /** Trusted source planner only. Neither plan nor reference is accepted by public call(). */
    void startTrustedBattlePlan(JSONObject plan,OfflineBattleCoordinator.Reply reply)throws Exception {
        if(battleDispatcher==null)throw failure("BATTLE_ENGINE_UNAVAILABLE");battleDispatcher.dispatch("startTrustedPlan",new JSONObject().put("plan",plan),false,reply);
    }
    void openTrustedBattlePlan(JSONObject reference,OfflineBattleCoordinator.Reply reply)throws Exception {
        if(battleDispatcher==null)throw failure("BATTLE_ENGINE_UNAVAILABLE");battleDispatcher.dispatch("openTrustedPlan",new JSONObject().put("reference",reference),false,reply);
    }
    private long countCards(){try(Cursor rows=master.rawQuery("SELECT count(*) FROM cards",null)){if(!rows.moveToFirst())throw failure("INVALID_MASTER");return rows.getLong(0);}}
    private JSONArray query(JSONObject args)throws Exception {
        only(args,"table","columns","filters","ids","search","order","limit","offset");String table=args.getString("table");if(!schema.containsKey(table))throw failure("UNKNOWN_MASTER_TABLE");
        List<String> columns=new ArrayList<>();JSONArray requested=args.optJSONArray("columns");
        if(args.has("columns")&&(requested==null||requested.length()==0||requested.length()>256))throw failure("INVALID_MASTER_COLUMNS");
        if(requested!=null)for(int n=0;n<requested.length();n++){String name=requested.getString(n);column(table,name);columns.add("\""+name+"\"");}
        List<String> where=new ArrayList<>(),bindings=new ArrayList<>();JSONObject filters=args.optJSONObject("filters");
        if(args.has("filters")&&(filters==null||filters.length()>256))throw failure("INVALID_MASTER_FILTER");
        if(filters!=null){Iterator<String> names=filters.keys();while(names.hasNext()){String name=names.next();column(table,name);Object value=filters.get(name);if(value==JSONObject.NULL)where.add("\""+name+"\" IS NULL");else{if(!(value instanceof String||value instanceof Number))throw failure("INVALID_MASTER_FILTER");where.add("\""+name+"\"=?");bindings.add(value.toString());}}}
        // Validated integer literals avoid Android 8's 999-bound-variable limit;
        // identifiers and all free-text values remain schema-checked/bound.
        if(args.has("ids")){column(table,"id");JSONArray ids=args.getJSONArray("ids");if(ids.length()>5000)throw failure("TOO_MANY_MASTER_IDS");if(ids.length()==0)return new JSONArray();List<String> values=new ArrayList<>();for(int n=0;n<ids.length();n++)values.add(Long.toString(integer(ids.get(n),-SAFE,SAFE)));where.add("id IN("+String.join(",",values)+")");}
        if(args.has("search")){JSONObject search=args.getJSONObject("search");only(search,"column","text");String name=search.getString("column");column(table,name);String text=search.getString("text");if(text.length()>200)throw failure("MASTER_SEARCH_TOO_LONG");where.add("instr(lower(\""+name+"\"),lower(?))>0");bindings.add(text);}
        String order=args.optString("order",schema.get(table).contains("id")?"id":"");
        if(!order.isEmpty()){if(!order.matches("[a-z][a-z0-9_]*(?: (?:ASC|DESC|asc|desc))?"))throw failure("INVALID_MASTER_ORDER");String[] parts=order.split(" ");column(table,parts[0]);order="\""+parts[0]+"\""+(parts.length==2?" "+parts[1]:"");}
        long limit=integer(args.opt("limit")==null?500:args.get("limit"),1,5000),offset=integer(args.opt("offset")==null?0:args.get("offset"),0,10000000);
        String sql="SELECT "+(columns.isEmpty()?"*":String.join(",",columns))+" FROM \""+table+"\""+(where.isEmpty()?"":" WHERE "+String.join(" AND ",where))+(order.isEmpty()?"":" ORDER BY "+order)+" LIMIT ? OFFSET ?";
        bindings.add(Long.toString(limit));bindings.add(Long.toString(offset));JSONArray result=new JSONArray();
        try(Cursor rows=master.rawQuery(sql,bindings.toArray(new String[0]))){while(rows.moveToNext())result.put(cursorObject(rows));}return result;
    }
    private JSONArray cardIndex()throws Exception {
        String[] fields={"id","name","rarity","element","open_at","hp_max","atk_max","def_max","resource_id","passive_skill_set_id","leader_skill_set_id","optimal_awakening_grow_type"};
        JSONArray result=new JSONArray();List<String> select=new ArrayList<>();for(String field:fields)select.add(schema.get("cards").contains(field)?"\""+field+"\"":"NULL AS \""+field+"\"");
        try(Cursor rows=master.rawQuery("SELECT "+String.join(",",select)+" FROM cards WHERE id%10=1 AND hp_max>300 AND leader_skill_set_id IS NOT NULL AND passive_skill_set_id IS NOT NULL ORDER BY id DESC",null)){
            while(rows.moveToNext()){long id=rows.getLong(0);if(!(id>=1000000&&id<3000000||id>=10000000||game.equals("sparking")&&id>=100000&&id<1000000))continue;JSONArray row=new JSONArray();for(int n=0;n<fields.length;n++){Object value=cell(rows,n);if(n==4){String date=value.toString().replace("-","");value=date.length()>=8&&date.substring(0,8).matches("[0-9]{8}")?Integer.parseInt(date.substring(0,8)):0;}row.put(value);}result.put(row);}
        }return result;
    }
    private String largeText(String sql,String... bindings){try(SQLiteStatement statement=workspace.compileStatement(sql)){for(int n=0;n<bindings.length;n++)statement.bindString(n+1,bindings[n]);return statement.simpleQueryForString();}}
    private String projectText(String key){try{return largeText("SELECT json FROM projects WHERE key=?",key);}catch(SQLiteDoneException error){throw failure("CREATOR_PROJECT_NOT_FOUND");}}
    private JSONObject validateProject(JSONObject project)throws Exception {
        if(!"dokkan-unit-forge".equals(project.optString("format"))||integer(project.opt("version"),1,1)!=1)throw failure("UNSUPPORTED_CREATOR_PROJECT");
        key(new JSONObject().put("key",project.getString("key")));JSONObject source=project.getJSONObject("source"),tables=project.getJSONObject("tables");
        if(!game.equals(source.optString("database",game)))throw failure("SOURCE_DATABASE_MISMATCH");source.put("database",game);
        if(source.has("contentId")&&!content.equals(source.opt("contentId")))throw failure("SOURCE_CONTENT_MISMATCH");
        JSONArray roots=tables.getJSONArray("cards");if(roots.length()!=1)throw failure("INVALID_ROOT_CARD");effectiveCard(project);
        integer(source.get("cardId"),1,SAFE);
        Instant.parse(project.getString("updatedAt"));jsonText(project);return project;
    }
    private static JSONObject effectiveCard(JSONObject project)throws Exception {
        JSONObject result=new JSONObject(project.getJSONObject("tables").getJSONArray("cards").getJSONObject(0).toString());JSONObject overrides=project.getJSONObject("cardOverrides");Iterator<String> keys=overrides.keys();while(keys.hasNext()){String key=keys.next();result.put(key,overrides.get(key));}return result;
    }
    private static void projectionSource(JSONObject project)throws Exception {if(integer(project.getJSONObject("source").get("cardId"),1,SAFE)!=integer(effectiveCard(project).get("id"),1,SAFE))throw failure("SOURCE_CARD_MISMATCH");}
    private boolean pending(String key){try(Cursor row=workspace.rawQuery("SELECT 1 FROM intents WHERE project_key=? AND definition IS NOT NULL AND completed=0",new String[]{key})){return row.moveToFirst();}}
    private JSONObject saveProject(JSONObject project)throws Exception {
        validateProject(project);String key=project.getString("key"),text=jsonText(project),updated=project.getString("updatedAt");if(pending(key))throw failure("CREATOR_FINISH_PENDING");
        workspace.beginTransaction();try{
            try(Cursor row=workspace.rawQuery("SELECT updated FROM projects WHERE key=?",new String[]{key})){if(row.moveToFirst()){int order=Instant.parse(updated).compareTo(Instant.parse(row.getString(0)));if(order<0||order==0&&!same(project,new JSONObject(projectText(key))))return new JSONObject().put("saved",false).put("superseded",true);}}
            workspace.execSQL("INSERT OR REPLACE INTO projects(key,json,revision,updated) VALUES(?,?,?,?)",new Object[]{key,text,hash(text),updated});workspace.setTransactionSuccessful();
        }finally{workspace.endTransaction();}return new JSONObject().put("saved",true).put("storage","device").put("revision",hash(text));
    }
    private JSONObject summary(JSONObject project)throws Exception {JSONObject card=effectiveCard(project);JSONArray reserved=new JSONArray().put(project.opt("targetId"));JSONArray forms=project.optJSONArray("formProjects");if(forms!=null)for(int n=0;n<forms.length();n++)reserved.put(forms.getJSONObject(n).opt("targetId"));return new JSONObject().put("key",project.getString("key")).put("name",card.optString("name")).put("targetId",project.opt("targetId")).put("reservedIds",reserved).put("updatedAt",project.optString("updatedAt")).put("rarity",card.opt("rarity")).put("lvMax",card.opt("lv_max")).put("element",card.opt("element")).put("resourceId",card.opt("resource_id")).put("sourceDatabase",game).put("origin","created").put("author",project.optJSONObject("patch")==null?"":project.getJSONObject("patch").optString("author"));}
    private JSONArray projects()throws Exception {JSONArray result=new JSONArray();try(Cursor rows=workspace.rawQuery("SELECT key FROM projects ORDER BY updated DESC,key",null)){while(rows.moveToNext())result.put(summary(new JSONObject(projectText(rows.getString(0)))));}return result;}
    private JSONObject deleteProject(String key)throws Exception {if(pending(key))throw failure("CREATOR_FINISH_PENDING");workspace.beginTransaction();try{workspace.delete("versions","project_key=?",new String[]{key});workspace.delete("intents","project_key=?",new String[]{key});workspace.delete("projects","key=?",new String[]{key});workspace.setTransactionSuccessful();}finally{workspace.endTransaction();}return new JSONObject().put("deleted",true);}
    private JSONObject versions(String key)throws Exception {String text=projectText(key);JSONArray versions=new JSONArray();try(Cursor rows=workspace.rawQuery("SELECT version_key,label,created,safety FROM versions WHERE project_key=? ORDER BY created DESC,version_key",new String[]{key})){while(rows.moveToNext())versions.put(new JSONObject().put("versionKey",rows.getString(0)).put("label",rows.getString(1)).put("createdAt",rows.getString(2)).put("safety",rows.getInt(3)!=0));}return new JSONObject().put("versions",versions).put("currentRevision",hash(text));}
    private void checkRevision(JSONObject args,String current)throws Exception {if(!hash(current).equals(args.getString("expectedCurrentRevision")))throw failure("CREATOR_REVISION_CONFLICT");}
    private String insertVersion(String key,String text,String label,boolean safety)throws Exception {
        if(label.trim().isEmpty()||label.length()>80||label.indexOf(0)>=0)throw failure("INVALID_VERSION_LABEL");if(safety)workspace.delete("versions","project_key=? AND safety=1",new String[]{key});
        String version=UUID.randomUUID().toString();workspace.execSQL("INSERT INTO versions VALUES(?,?,?,?,?,?)",new Object[]{version,key,label,Instant.now().toString(),text,safety?1:0});
        workspace.execSQL("DELETE FROM versions WHERE project_key=? AND version_key NOT IN(SELECT version_key FROM versions WHERE project_key=? ORDER BY created DESC,version_key DESC LIMIT 10)",new Object[]{key,key});
        while(true){long bytes;try(Cursor rows=workspace.rawQuery("SELECT COALESCE(sum(length(CAST(json AS BLOB))),0) FROM versions WHERE project_key=?",new String[]{key})){rows.moveToFirst();bytes=rows.getLong(0);}if(bytes<=HISTORY_LIMIT)break;workspace.execSQL("DELETE FROM versions WHERE version_key=(SELECT version_key FROM versions WHERE project_key=? AND version_key!=? ORDER BY created,version_key LIMIT 1)",new Object[]{key,version});}return version;
    }
    private JSONObject saveVersion(JSONObject args)throws Exception {String key=key(args);workspace.beginTransaction();String id;try{String text=projectText(key);checkRevision(args,text);if(pending(key))throw failure("CREATOR_FINISH_PENDING");id=insertVersion(key,text,args.getString("label"),false);workspace.setTransactionSuccessful();}finally{workspace.endTransaction();}return versions(key).put("saved",true).put("versionKey",id);}
    private JSONObject versionProject(String key,String version)throws Exception {try{return new JSONObject(largeText("SELECT json FROM versions WHERE project_key=? AND version_key=?",key,version));}catch(SQLiteDoneException error){throw failure("CREATOR_VERSION_NOT_FOUND");}}
    private JSONObject restoreVersion(JSONObject args)throws Exception {String key=key(args);JSONObject project;workspace.beginTransaction();try{String current=projectText(key);checkRevision(args,current);if(pending(key))throw failure("CREATOR_FINISH_PENDING");project=versionProject(key,args.getString("versionKey"));long millis=Math.max(System.currentTimeMillis(),Instant.parse(new JSONObject(current).getString("updatedAt")).toEpochMilli()+1);project.put("updatedAt",Instant.ofEpochMilli(millis).toString());validateProject(project);String text=jsonText(project);insertVersion(key,current,"Before restoring an earlier version",true);workspace.execSQL("UPDATE projects SET json=?,revision=?,updated=? WHERE key=?",new Object[]{text,hash(text),project.getString("updatedAt"),key});workspace.setTransactionSuccessful();}finally{workspace.endTransaction();}return versions(key).put("saved",true).put("project",project);}
    private JSONObject settings()throws Exception {try(Cursor rows=workspace.rawQuery("SELECT json FROM preferences WHERE id=1",null)){return rows.moveToFirst()?new JSONObject(rows.getString(0)):new JSONObject();}}
    private Object saveSettings(JSONObject args)throws Exception {Set<String> allowed=new HashSet<>(Arrays.asList("theme","text","contrast","motion","help","mode","language","quality","expert","animations","sound","compact","reduceMotion"));JSONObject value=args.optJSONObject("settings");if(value==null)value=args;else only(args,"settings");Iterator<String> names=value.keys();while(names.hasNext()){String name=names.next();Object item=value.get(name);if(!allowed.contains(name)||!(item instanceof String||item instanceof Number||item instanceof Boolean)||item.toString().length()>256)throw failure("UNSUPPORTED_OFFLINE_SETTING");}if(value.toString().length()>8192)throw failure("INVALID_SETTINGS");workspace.execSQL("INSERT OR REPLACE INTO preferences VALUES(1,?)",new Object[]{value.toString()});return value;}
    private static void unsupported(JSONObject project)throws Exception {
        if(project.has("awaken")&&!project.isNull("awaken"))throw failure("OFFICIAL_AWAKENING_NOT_SHAREABLE");
        for(String key:Arrays.asList("formProjects","transformLinks"))if(project.has(key)&&(project.optJSONArray(key)==null||project.getJSONArray(key).length()!=0))throw failure("MULTIFORM_INTEGRATION_REQUIRED");
        for(String key:Arrays.asList("assets","packedAssets","generatedFiles"))if(project.has(key)&&(project.optJSONArray(key)==null||project.getJSONArray(key).length()!=0))throw failure("CUSTOM_ASSET_INTEGRATION_REQUIRED");
        for(String key:Arrays.asList("actionHooks","animationAssignments"))if(project.has(key)&&!project.isNull(key)&&(project.optJSONObject(key)==null||project.getJSONObject(key).length()!=0))throw failure("CUSTOM_RUNTIME_INTEGRATION_REQUIRED");
        for(String key:Arrays.asList("sourceDependencies","battlePoseBinding"))if(project.has(key)&&!project.isNull(key))throw failure("CUSTOM_RUNTIME_INTEGRATION_REQUIRED");
    }
    private JSONArray proveBaseline(JSONObject project)throws Exception {JSONArray proven=new JSONArray();JSONObject tables=project.getJSONObject("tables");Iterator<String> names=tables.keys();while(names.hasNext()){String table=names.next();if(table.equals("cards"))continue;JSONArray rows=tables.getJSONArray(table);if(rows.length()==0||projectionTables.contains(table))continue;if(!schema.containsKey(table)||!schema.get(table).contains("id"))throw failure("UNSUPPORTED_MODIFIED_TABLE");for(int n=0;n<rows.length();n++){JSONObject row=rows.getJSONObject(n);long id=integer(row.get("id"),-SAFE,SAFE);JSONArray original=query(new JSONObject().put("table",table).put("filters",new JSONObject().put("id",id)).put("limit",1));if(original.length()!=1||!same(row,original.getJSONObject(0)))throw failure("UNSUPPORTED_MODIFIED_TABLE");}proven.put(table);}return proven;}
    private JSONObject prepare(String key)throws Exception {
        String text=projectText(key),revision=hash(text);JSONObject project=validateProject(new JSONObject(text));projectionSource(project);unsupported(project);JSONArray proof=proveBaseline(project);JSONObject card=effectiveCard(project);String definitionId=project.optJSONObject("patch")==null?key:project.getJSONObject("patch").optString("uuid",key);if(!definitionId.matches("[A-Za-z0-9_.:-]{1,100}")||definitionId.startsWith("tournament-exclusive:"))throw failure("INVALID_DEFINITION_ID");
        JSONObject library=new JSONObject(core.execute("creator.library",profile,null,"{}"));long current=0;JSONArray definitions=library.getJSONArray("definitions");for(int n=0;n<definitions.length();n++){JSONObject row=definitions.getJSONObject(n);if(definitionId.equals(row.getString("definition_id")))current=integer(row.get("version"),1,SAFE);}
        String snapshot=null,command=null;JSONObject context=null;
        try(Cursor old=workspace.rawQuery("SELECT snapshot,context,command,revision FROM intents WHERE project_key=?",new String[]{key})){if(old.moveToFirst()&&revision.equals(old.getString(3))){JSONObject candidate=new JSONObject(old.getString(1));if(integer(candidate.get("version"),1,SAFE)>=current){snapshot=old.getString(0);context=candidate;command=old.getString(2);}}}
        if(context==null){if(current>=SAFE)throw failure("CREATOR_VERSION_LIMIT");long numeric=integer(card.get("rarity"),4,5),level=integer(card.get("lv_max"),1,Integer.MAX_VALUE);String rarity=numeric==4?"UR":level==180?"SLR":level==200?"GR":"LR";context=new JSONObject().put("contentId",content).put("sourceDatabase",game).put("definitionId",definitionId).put("version",current+1).put("rarity",rarity);
            if(current>0){JSONObject previous=new JSONObject(core.execute("creator.export",profile,null,new JSONObject().put("definition_id",definitionId).put("version",current).toString()));JSONObject credit=previous.optJSONObject("creator");if(credit!=null){context.put("creatorId",credit.getString("id")).put("creatorName",credit.getString("name"));}if(previous.has("stat_policy"))context.put("statPolicy",previous.getString("stat_policy"));}
            snapshot=UUID.randomUUID().toString();command="creator-finish:"+UUID.randomUUID();workspace.execSQL("INSERT OR REPLACE INTO intents(project_key,snapshot,revision,context,command,definition,completed) VALUES(?,?,?,?,?,NULL,0)",new Object[]{key,snapshot,revision,context.toString(),command});
        }
        return new JSONObject().put("snapshot",snapshot).put("project",project).put("context",context).put("unchangedTables",proof);
    }
    private JSONObject expectedDefinition(JSONObject project,JSONObject context)throws Exception {JSONObject card=effectiveCard(project),tables=new JSONObject(),original=project.getJSONObject("tables");Iterator<String> names=original.keys();while(names.hasNext()){String table=names.next();if(!table.equals("cards")&&projectionTables.contains(table)&&original.getJSONArray(table).length()>0)tables.put(table,original.getJSONArray(table));}
        JSONObject result=new JSONObject().put("format","offline-dokkan-definition").put("schema_version",1).put("definition_id",context.getString("definitionId")).put("version",context.getLong("version")).put("source",new JSONObject().put("content_id",content).put("master_id",project.getJSONObject("source").getLong("cardId"))).put("rarity",context.getString("rarity")).put("fully_awakened",true).put("card",card).put("tables",tables);
        if(card.getLong("lv_max")>150)result.put("progression_policy","creator-lr-extended-v1");String stat=project.optString("statPolicy",context.optString("statPolicy",""));if(context.has("statPolicy")&&project.has("statPolicy")&&!stat.equals(context.getString("statPolicy")))throw failure("STAT_POLICY_MISMATCH");if(!stat.isEmpty())result.put("stat_policy",stat);
        if(context.has("creatorId"))result.put("creator",new JSONObject().put("id",context.getString("creatorId")).put("name",context.getString("creatorName")));return result;
    }
    private JSONObject finish(String key,String snapshot,JSONObject definition)throws Exception {
        String command,storedDefinition;JSONObject context;
        workspace.beginTransaction();try{
        String current=projectText(key);
        try(Cursor intent=workspace.rawQuery("SELECT revision,context,command FROM intents WHERE project_key=? AND snapshot=?",new String[]{key,snapshot})){if(!intent.moveToFirst()||!hash(current).equals(intent.getString(0)))throw failure("CREATOR_SNAPSHOT_STALE");context=new JSONObject(intent.getString(1));command=intent.getString(2);}
        storedDefinition=largeText("SELECT COALESCE(definition,'') FROM intents WHERE project_key=? AND snapshot=?",key,snapshot);if(storedDefinition.isEmpty())storedDefinition=null;
        JSONObject project=validateProject(new JSONObject(current));projectionSource(project);unsupported(project);proveBaseline(project);
        if(!same(expectedDefinition(project,context),definition))throw failure("CREATOR_PROJECTION_MISMATCH");if(storedDefinition!=null&&!same(new JSONObject(storedDefinition),definition))throw failure("CREATOR_INTENT_CONFLICT");String document=jsonText(definition);if(document.getBytes(StandardCharsets.UTF_8).length>DEFINITION_LIMIT)throw failure("DEFINITION_TOO_LARGE");
        workspace.execSQL("UPDATE intents SET definition=? WHERE project_key=? AND snapshot=?",new Object[]{document,key,snapshot});workspace.setTransactionSuccessful();
        }finally{workspace.endTransaction();}
        JSONObject result;
        try{result=new JSONObject(core.execute("creator.finish",profile,command+":collection-v1",new JSONObject().put("definition",definition).toString()));}
        catch(RuntimeException error){workspace.execSQL("UPDATE intents SET definition=NULL WHERE project_key=? AND snapshot=? AND completed=0",new Object[]{key,snapshot});throw error;}
        long instance=integer(result.get("instance_id"),1,SAFE);if(!(result.get("available") instanceof Boolean)||!(result.get("newly_owned") instanceof Boolean))throw failure("CREATOR_COLLECTION_UNCONFIRMED");
        boolean available=false;JSONArray owned=new JSONObject(core.execute("profile.snapshot",profile,null,"{}")).getJSONArray("cards");
        for(int n=0;n<owned.length();n++){JSONObject card=owned.getJSONObject(n),created=card.optJSONObject("created_definition");if(card.getLong("instance_id")==instance&&created!=null&&context.getString("definitionId").equals(created.optString("definition_id"))){available=true;break;}}
        workspace.execSQL("UPDATE intents SET completed=1 WHERE project_key=? AND snapshot=?",new Object[]{key,snapshot});JSONObject library=new JSONObject(core.execute("creator.library",profile,null,"{}"));return new JSONObject().put("imported",true).put("definitionId",context.getString("definitionId")).put("version",context.getLong("version")).put("instanceId",instance).put("available",available).put("newlyOwned",result.getBoolean("newly_owned")).put("library",library).put("banner",new JSONObject().put("status","not_configured").put("drawable",false).put("reason","trusted_catalog_allocation_required"));
    }
    @Override public void close(){workspace.close();master.close();}
}
