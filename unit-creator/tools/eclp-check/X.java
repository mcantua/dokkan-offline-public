import com.personal.aihub.EclpCodec; import java.io.*; import java.util.*; import java.nio.file.*;
public class X { public static void main(String[] a) throws Exception {
  File f=new File(a[0]); EclpCodec.Header h=EclpCodec.header(f); org.json.JSONObject m=new org.json.JSONObject(h.metadata);
  File out=new File(a[1]); out.mkdirs();
  List<EclpCodec.Entry> es=EclpCodec.extract(f,out,new File("/tmp"),m.getString("uuid"),m.getString("name"),m.getString("version"));
  for(EclpCodec.Entry e:es) System.out.println(e.path+" "+e.file.length());
}}
