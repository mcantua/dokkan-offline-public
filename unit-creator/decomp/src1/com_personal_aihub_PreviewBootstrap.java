package com.personal.aihub;
public final class PreviewBootstrap {
    public static final int MAX_CHUNK_UNITS = 48000;
    public static final int MAX_REQUEST_BYTES = 3145728;
    private static final java.util.concurrent.atomic.AtomicLong SEQUENCE = None;
    private static final String STATE = "window.__forgePreviewBootstrap";
    private final java.util.List chunks;
    private final String documentId;
    private final long generation;
    private final String nonce;
    private final int requestBytes;
    private final int requestUnits;

    static PreviewBootstrap()
    {
        com.personal.aihub.PreviewBootstrap.SEQUENCE = new java.util.concurrent.atomic.AtomicLong();
        return;
    }

    public PreviewBootstrap(String p5, String p6, String p7)
    {
        this.nonce = com.personal.aihub.PreviewBootstrap.identifier(p5, "session nonce");
        this.documentId = com.personal.aihub.PreviewBootstrap.identifier(p6, "document identifier");
        if ((p7 == 0) || ((p7.isEmpty()) || (p7.length() > 3145728))) {
            throw new IllegalArgumentException("Preview request exceeds its transport bounds.");
        } else {
            IllegalStateException v5_9 = 0;
            int v0_1 = 0;
            while (v0_1 < p7.length()) {
                boolean v1_13 = p7.charAt(v0_1);
                if (!Character.isHighSurrogate(v1_13)) {
                    if (Character.isLowSurrogate(v1_13)) {
                        throw new IllegalArgumentException("Preview request contains an incomplete Unicode character.");
                    }
                } else {
                    v0_1++;
                    if ((v0_1 >= p7.length()) || (!Character.isLowSurrogate(p7.charAt(v0_1)))) {
                        throw new IllegalArgumentException("Preview request contains an incomplete Unicode character.");
                    }
                }
                v0_1++;
            }
            int v0_4 = p7.getBytes(java.nio.charset.StandardCharsets.UTF_8).length;
            this.requestBytes = v0_4;
            this.requestUnits = p7.length();
            if (v0_4 > 3145728) {
                throw new IllegalArgumentException("Preview request exceeds 3 MiB of UTF-8.");
            } else {
                try {
                    new org.json.JSONObject(p7);
                    String v6_6 = new java.util.ArrayList();
                } catch (IllegalStateException v5_13) {
                    throw new IllegalArgumentException("Preview request must be a JSON object.", v5_13);
                }
                while (v5_9 < p7.length()) {
                    int v0_10 = Math.min((48000 + v5_9), p7.length());
                    if ((v0_10 < p7.length()) && ((Character.isHighSurrogate(p7.charAt((v0_10 - 1)))) && (Character.isLowSurrogate(p7.charAt(v0_10))))) {
                        v0_10--;
                    }
                    v6_6.add(p7.substring(v5_9, v0_10));
                    v5_9 = v0_10;
                }
                this.chunks = java.util.Collections.unmodifiableList(v6_6);
                IllegalStateException v5_17 = com.personal.aihub.PreviewBootstrap.SEQUENCE.incrementAndGet();
                this.generation = v5_17;
                if ((v5_17 < 1) || (v5_17 > 9007199254740991)) {
                    throw new IllegalStateException("Preview session sequence exhausted.");
                } else {
                    return;
                }
            }
        }
    }

    private String documentGuard()
    {
        String v0_2 = new StringBuilder("if(window.__forgeNativeDocumentId!==");
        v0_2.append(com.personal.aihub.PreviewBootstrap.quote(this.documentId));
        v0_2.append(")return false;");
        return v0_2.toString();
    }

    private static String identifier(String p2, String p3)
    {
        if ((p2 == null) || (!p2.matches("[A-Za-z0-9_-]{16,128}"))) {
            StringBuilder v0_3 = new StringBuilder("Invalid preview ");
            v0_3.append(p3);
            v0_3.append(".");
            throw new IllegalArgumentException(v0_3.toString());
        } else {
            return p2;
        }
    }

    private static String quote(String p2)
    {
        return org.json.JSONObject.quote(p2).replace("\u2028", "\\u2028").replace("\u2029", "\\u2029");
    }

    private String sessionGuard()
    {
        String v0_1 = new StringBuilder();
        v0_1.append(this.documentGuard());
        v0_1.append("var s=window.__forgePreviewBootstrap;if(!s||s.generation!==");
        v0_1.append(this.generation);
        v0_1.append("||s.nonce!==");
        v0_1.append(com.personal.aihub.PreviewBootstrap.quote(this.nonce));
        v0_1.append("||s.phase!==\'pending\')return false;");
        return v0_1.toString();
    }

    public String beginScript()
    {
        String v0_1 = new StringBuilder("(function(){");
        v0_1.append(this.documentGuard());
        v0_1.append("var old=window.__forgePreviewBootstrap;if(old&&(old.mounted||old.generation>=");
        v0_1.append(this.generation);
        v0_1.append("))return false;window.__forgePreviewBootstrap={generation:");
        v0_1.append(this.generation);
        v0_1.append(",nonce:");
        v0_1.append(com.personal.aihub.PreviewBootstrap.quote(this.nonce));
        v0_1.append(",phase:\'pending\',mounted:false,next:0,bytes:0,units:0,chunks:[]};return true;})()");
        return v0_1.toString();
    }

    public String cancelScript()
    {
        String v0_1 = new StringBuilder("(function(){");
        v0_1.append(this.sessionGuard());
        v0_1.append("delete s.chunks;s.phase=\'canceled\';return true;})()");
        return v0_1.toString();
    }

    public int chunkCount()
    {
        return this.chunks.size();
    }

    public String chunkScript(int p4)
    {
        String v0_2 = ((String) this.chunks.get(p4));
        StringBuilder v1_1 = new StringBuilder("(function(){");
        v1_1.append(this.sessionGuard());
        v1_1.append("if(s.next!==");
        v1_1.append(p4);
        v1_1.append(")return false;var text=");
        v1_1.append(com.personal.aihub.PreviewBootstrap.quote(v0_2));
        v1_1.append(";var bytes=new TextEncoder().encode(text).length;if(text.length>48000||s.units+text.length>");
        v1_1.append(this.requestUnits);
        v1_1.append("||s.bytes+bytes>");
        v1_1.append(this.requestBytes);
        v1_1.append("||s.bytes+bytes>3145728){delete s.chunks;s.phase=\'canceled\';return false;}s.chunks.push(text);s.next++;s.units+=text.length;s.bytes+=bytes;return true;})()");
        return v1_1.toString();
    }

    public java.util.List chunkScripts()
    {
        java.util.List v0_2 = new java.util.ArrayList(this.chunks.size());
        int v1_1 = 0;
        while (v1_1 < this.chunks.size()) {
            v0_2.add(this.chunkScript(v1_1));
            v1_1++;
        }
        return java.util.Collections.unmodifiableList(v0_2);
    }

    public String documentId()
    {
        return this.documentId;
    }

    public String mountScript(String p3)
    {
        if ((p3 == null) || (p3.isEmpty())) {
            throw new IllegalArgumentException("Preview page script is required.");
        } else {
            StringBuilder v0_0 = new StringBuilder("(function(){");
            v0_0.append(this.sessionGuard());
            v0_0.append("if(s.next!==");
            v0_0.append(this.chunks.size());
            v0_0.append("||s.units!==");
            v0_0.append(this.requestUnits);
            v0_0.append("||s.bytes!==");
            v0_0.append(this.requestBytes);
            v0_0.append(")return false;var request;try{request=JSON.parse(s.chunks.join(\'\'));}catch(error){delete s.chunks;s.phase=\'canceled\';return false;}delete s.chunks;s.phase=\'mounted\';s.mounted=true;window.__forgeAnimation=request;(function(){\n");
            v0_0.append(p3);
            v0_0.append("\n}).call(window);return true;})()");
            return v0_0.toString();
        }
    }

    public String nonce()
    {
        return this.nonce;
    }

    public int requestBytes()
    {
        return this.requestBytes;
    }
}
