package com.personal.aihub;
 class CpkWriter$1 implements java.util.function.Function {
    final synthetic java.io.ByteArrayOutputStream val$byteArrayOutputStream;
    final synthetic java.util.LinkedHashMap val$linkedHashMap;

    CpkWriter$1(java.util.LinkedHashMap p1, java.io.ByteArrayOutputStream p2)
    {
        this.val$linkedHashMap = p1;
        this.val$byteArrayOutputStream = p2;
        return;
    }

    public final Object apply(Object p3)
    {
        return com.personal.aihub.CpkWriter.lambda$0(this.val$linkedHashMap, this.val$byteArrayOutputStream, ((String) p3));
    }
}
