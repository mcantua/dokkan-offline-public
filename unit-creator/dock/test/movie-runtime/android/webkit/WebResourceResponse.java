package android.webkit;
import java.io.InputStream;
import java.util.Map;
/** Holds native response values for the focused JVM range check; excluded from app compilation. */
public class WebResourceResponse {
    private final String mime;private final int status;private final Map<String,String> headers;private final InputStream data;
    public WebResourceResponse(String mime,String encoding,InputStream data){this(mime,encoding,200,"OK",null,data);}
    public WebResourceResponse(String mime,String encoding,int status,String reason,Map<String,String> headers,InputStream data){this.mime=mime;this.status=status;this.headers=headers;this.data=data;}
    public int getStatusCode(){return status;}public String getMimeType(){return mime;}public InputStream getData(){return data;}public Map<String,String> getResponseHeaders(){return headers;}
}
