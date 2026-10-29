package android.database.sqlite;

import android.database.Cursor;
import java.io.*;
import java.util.*;
import org.json.*;

/** JVM test adapter only: executes production validator SQL against actual read-only SQLite files. */
public final class SQLiteDatabase {
    public static final int OPEN_READONLY=1;
    public interface CursorFactory {}
    private final String path;
    private SQLiteDatabase(String path){this.path=path;}
    public static SQLiteDatabase openDatabase(String path,CursorFactory factory,int flags){return new SQLiteDatabase(path);}
    public Cursor rawQuery(String sql,String[] args){
        try{
            List<String> command=new ArrayList<String>(Arrays.asList("python3","-c","import sqlite3,json,sys; db=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True); print(json.dumps(db.execute(sys.argv[2],sys.argv[3:]).fetchall())); db.close()",path,sql));
            if(args!=null)command.addAll(Arrays.asList(args));
            Process process=new ProcessBuilder(command).redirectErrorStream(true).start();ByteArrayOutputStream out=new ByteArrayOutputStream();
            try(InputStream in=process.getInputStream()){byte[] block=new byte[4096];int n;while((n=in.read(block))!=-1)out.write(block,0,n);}
            if(process.waitFor()!=0)throw new IOException(new String(out.toByteArray(),"UTF-8"));
            final JSONArray rows=new JSONArray(new String(out.toByteArray(),"UTF-8"));
            return new Cursor(){int row=-1;public boolean moveToNext(){return ++row<rows.length();}public long getLong(int column){try{return rows.getJSONArray(row).getLong(column);}catch(Exception e){throw new RuntimeException(e);}}public String getString(int column){try{return rows.getJSONArray(row).getString(column);}catch(Exception e){throw new RuntimeException(e);}}public boolean isNull(int column){try{return rows.getJSONArray(row).isNull(column);}catch(Exception e){throw new RuntimeException(e);}}public void close(){}};
        }catch(Exception e){throw new IllegalStateException("SQLite fixture query failed",e);}
    }
    public void close(){}
}
