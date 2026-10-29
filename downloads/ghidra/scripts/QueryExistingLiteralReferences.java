// Read existing references to ONE already-reviewed resource literal only.
// No disassembly, analysis, decompilation, string dump or source mutation.
// @category OfflineDokkan.Static
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import com.google.gson.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class QueryExistingLiteralReferences extends GhidraScript {
    @Override public void run() throws Exception {
        String[] args=getScriptArgs();
        if(args.length!=2||!currentProgram.getName().equals("OriginalDokkanEngine.dylib"))
            throw new IllegalArgumentException("Exact retained admitted program and private request/output required");
        JsonObject request=JsonParser.parseString(Files.readString(Paths.get(args[0]))).getAsJsonObject();
        if(!request.get("kind").getAsString().equals("exact-tutorial0-filesystem-pointer-xrefs")||
           !request.get("source_sha256").getAsString().equals("efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222"))
            throw new IllegalArgumentException("One existing reviewed resource target only");
        Address literal=toAddr(request.get("private_literal_address").getAsLong());
        LinkedHashSet<Address> targets=new LinkedHashSet<>();targets.add(literal);
        Data containing=currentProgram.getListing().getDataContaining(literal);
        JsonObject result=new JsonObject();result.addProperty("kind","existing-reference-manager-only");
        result.addProperty("private_literal_address",literal.toString());
        if(containing!=null&&containing.getLength()<=4096){
            JsonObject object=new JsonObject();object.addProperty("private_address",containing.getMinAddress().toString());
            object.addProperty("bytes",containing.getLength());object.addProperty("datatype",containing.getDataType().getName());
            result.add("existing_data_object",object);targets.add(containing.getMinAddress());
        }else result.add("existing_data_object",JsonNull.INSTANCE);
        JsonArray references=new JsonArray();
        for(Address target:targets){int count=0;
            for(Reference reference:currentProgram.getReferenceManager().getReferencesTo(target)){
                if(++count>256)throw new IllegalStateException("Existing-reference bound exceeded");
                JsonObject item=new JsonObject();item.addProperty("private_from",reference.getFromAddress().toString());
                item.addProperty("private_to",reference.getToAddress().toString());item.addProperty("type",reference.getReferenceType().getName());
                Function function=currentProgram.getFunctionManager().getFunctionContaining(reference.getFromAddress());
                if(function!=null)item.addProperty("private_function_start",function.getEntryPoint().toString());
                references.add(item);
            }
        }
        result.add("references",references);result.addProperty("new_analysis_or_decompile",false);
        result.addProperty("values_or_other_strings_read",false);
        result.addProperty("zero_references_does_not_prove_no_native_consumer",true);
        Files.writeString(Paths.get(args[1]),new GsonBuilder().setPrettyPrinting().create().toJson(result)+"\n",StandardCharsets.UTF_8);
        println("One existing-literal metadata query completed; references="+references.size());
    }
}
