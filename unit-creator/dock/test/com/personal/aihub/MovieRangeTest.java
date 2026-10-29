package com.personal.aihub;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import android.webkit.WebResourceResponse;

/** Actual-file range semantics only; no claim about Android decoder or player rendering. */
public final class MovieRangeTest {
    static int checks;
    static void ok(String label,boolean condition){if(!condition)throw new AssertionError(label);checks++;System.out.println("PASS "+label);}
    static byte[] body(WebResourceResponse response)throws Exception{try(InputStream in=response.getData()){ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[31];int n;while((n=in.read(b))!=-1)out.write(b,0,n);return out.toByteArray();}}
    static void range(File file,String request,int start,int end)throws Exception{
        WebResourceResponse r=MovieCache.serve(file,request);byte[] expected=new byte[end-start+1];for(int i=0;i<expected.length;i++)expected[i]=(byte)(start+i);
        ok(request+" returns exact206 bytes and limits the stream",r.getStatusCode()==206&&r.getResponseHeaders().get("Content-Range").equals("bytes "+start+"-"+end+"/256")&&Arrays.equals(expected,body(r)));
    }
    public static void main(String[]args)throws Exception{
        Path root=Files.createTempDirectory("dokkan-movie-range-");
        try{
            File file=root.resolve("movie.video").toFile();byte[] bytes=new byte[256];for(int i=0;i<bytes.length;i++)bytes[i]=(byte)i;Files.write(file.toPath(),bytes);
            WebResourceResponse full=MovieCache.serve(file,null);ok("full file advertises byte ranges",full.getStatusCode()==200&&"bytes".equals(full.getResponseHeaders().get("Accept-Ranges"))&&Arrays.equals(bytes,body(full)));
            range(file,"bytes=32-47",32,47);range(file,"bytes=240-",240,255);range(file,"bytes=-8",248,255);range(file,"bytes=250-999",250,255);
            for(String invalid:new String[]{"bytes=256-","bytes=4-2","bytes=-0","bytes=0-1,4-5","bytes=999999999999999999999-"}){
                WebResourceResponse r=MovieCache.serve(file,invalid);ok(invalid+" is safely rejected",r.getStatusCode()==416&&"bytes */256".equals(r.getResponseHeaders().get("Content-Range"))&&body(r).length==0);
            }
            File linked=root.resolve("link.video").toFile();Files.createSymbolicLink(linked.toPath(),file.toPath());ok("cache-file symlink is not served",MovieCache.serve(linked,"bytes=0-5").getStatusCode()==404&&file.length()==256);
            System.out.println(checks+" cached-movie range assertions passed; physical Android decoder/seek remains a device check.");
        }finally{PublicStorage.removeTree(root);}
    }
}
