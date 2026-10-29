// Selected-function static decompilation only. Original code is never executed.
// @category OfflineDokkan.Static
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.SourceType;
import ghidra.program.model.pcode.PcodeOpAST;
import com.google.gson.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

public class ScopedAuthDecompile extends GhidraScript {
    private static String sha(byte[] bytes) throws Exception {
        StringBuilder out = new StringBuilder();
        for (byte value : MessageDigest.getInstance("SHA-256").digest(bytes))
            out.append(String.format("%02x", value & 255));
        return out.toString();
    }
    @Override public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 2 || currentProgram == null)
            throw new IllegalArgumentException("Private scope/output arguments required");
        Path config = Paths.get(args[0]).toAbsolutePath().normalize();
        Path output = Paths.get(args[1]).toAbsolutePath().normalize();
        if (!config.toString().contains("/offline-dokkan/private/") ||
            !output.toString().contains("/offline-dokkan/private/ghidra/"))
            throw new IllegalArgumentException("Detailed input/output must remain private");
        JsonObject scope = JsonParser.parseString(Files.readString(config)).getAsJsonObject();
        if (!scope.get("expected_source_sha256").getAsString().equals(currentProgram.getExecutableSHA256()))
            throw new IllegalArgumentException("Imported source identity changed");
        JsonArray functions = scope.getAsJsonArray("functions");
        if (functions.size() == 0 || functions.size() > 8)
            throw new IllegalArgumentException("Selected-function bound exceeded");
        Files.createDirectories(output);
        JsonArray results = new JsonArray();
        // Exact imported standard-runtime contracts. They do not return to
        // the next instruction; allowing fallthrough invents adjacent code in
        // exception-cleanup output. This changes tool metadata, not the image.
        Set<String> noReturnImports = Set.of("__Unwind_Resume", "_Unwind_Resume",
            "___stack_chk_fail", "__stack_chk_fail");
        Iterator<Function> importedFunctions = currentProgram.getFunctionManager().getExternalFunctions();
        while (importedFunctions.hasNext()) {
            Function imported = importedFunctions.next();
            if (noReturnImports.contains(imported.getName())) imported.setNoReturn(true);
        }
        for (String runtimeName : noReturnImports)
            for (Function named : getGlobalFunctions(runtimeName)) named.setNoReturn(true);
        // Declare every admitted entry before decompilation. This makes a
        // selected tail target an explicit function boundary rather than an
        // accidental unreported extension of the caller's body.
        for (JsonElement value : functions) {
            JsonObject item = value.getAsJsonObject();
            String label = item.get("label").getAsString();
            int length = item.get("bytes").getAsInt();
            if (!label.matches("[A-Za-z0-9_.-]{1,60}") || length < 4 || length > 16384)
                throw new IllegalArgumentException("Selected-function configuration invalid");
            Address start = currentProgram.getAddressFactory().getDefaultAddressSpace()
                .getAddress(Long.parseUnsignedLong(item.get("address").getAsString().replaceFirst("^0x", ""), 16));
            byte[] bytes = new byte[length];
            if (currentProgram.getMemory().getBytes(start, bytes) != length ||
                !sha(bytes).equals(item.get("sha256").getAsString()))
                throw new IllegalArgumentException("Selected-body identity changed");
            AddressSet body = new AddressSet(start, start.add(length - 1));
            if (!new DisassembleCommand(start, body, true).applyTo(currentProgram, monitor))
                throw new IllegalStateException("Selected disassembly unavailable");
            Function existing = getFunctionAt(start);
            if (existing == null)
                currentProgram.getFunctionManager().createFunction("scoped_" + label, start, body, SourceType.USER_DEFINED);
            else existing.setBody(body);
        }
        DecompInterface decompiler = new DecompInterface();
        decompiler.toggleCCode(true);
        decompiler.toggleSyntaxTree(true);
        decompiler.setSimplificationStyle("decompile");
        if (!decompiler.openProgram(currentProgram))
            throw new IllegalStateException("Selected program decompiler unavailable");
        try {
            for (JsonElement value : functions) {
                monitor.checkCancelled();
                JsonObject item = value.getAsJsonObject();
                String label = item.get("label").getAsString();
                int length = item.get("bytes").getAsInt();
                if (!label.matches("[A-Za-z0-9_.-]{1,60}") || length < 4 || length > 16384)
                    throw new IllegalArgumentException("Selected-function configuration invalid");
                String number = item.get("address").getAsString().replaceFirst("^0x", "");
                Address start = currentProgram.getAddressFactory().getDefaultAddressSpace()
                    .getAddress(Long.parseUnsignedLong(number, 16));
                byte[] bytes = new byte[length];
                if (currentProgram.getMemory().getBytes(start, bytes) != length ||
                    !sha(bytes).equals(item.get("sha256").getAsString()))
                    throw new IllegalArgumentException("Selected-body identity changed");
                AddressSet body = new AddressSet(start, start.add(length - 1));
                DisassembleCommand disassemble = new DisassembleCommand(start, body, true);
                if (!disassemble.applyTo(currentProgram, monitor))
                    throw new IllegalStateException("Selected disassembly unavailable");
                Function function = getFunctionAt(start);
                if (function == null)
                    function = currentProgram.getFunctionManager().createFunction(
                        "scoped_" + label, start, body, SourceType.USER_DEFINED);
                else function.setBody(body);
                DecompileResults result = decompiler.decompileFunction(function, 45, monitor);
                JsonObject receipt = new JsonObject();
                receipt.addProperty("label", label);
                receipt.addProperty("bytes", length);
                receipt.addProperty("completed", result.decompileCompleted());
                receipt.addProperty("timed_out", result.isTimedOut());
                receipt.addProperty("error", result.getErrorMessage());
                if (result.decompileCompleted() && result.getDecompiledFunction() != null) {
                    Files.writeString(output.resolve(label + ".c"),
                        result.getDecompiledFunction().getC(), StandardCharsets.UTF_8);
                    if (result.getHighFunction() != null) {
                        StringBuilder operations = new StringBuilder();
                        SortedSet<Address> footprint = new TreeSet<>();
                        Iterator<PcodeOpAST> iterator = result.getHighFunction().getPcodeOps();
                        while (iterator.hasNext()) {
                            PcodeOpAST operation = iterator.next();
                            operations.append(operation.toString()).append('\n');
                            Address instruction = operation.getSeqnum().getTarget();
                            if (instruction.getAddressSpace().equals(start.getAddressSpace()))
                                footprint.add(instruction);
                        }
                        JsonArray locations = new JsonArray();
                        int outside = 0;
                        for (Address instruction : footprint) {
                            locations.add(instruction.toString());
                            if (!body.contains(instruction)) outside++;
                        }
                        receipt.addProperty("high_pcode_unique_instruction_sites", footprint.size());
                        receipt.addProperty("high_pcode_sites_outside_declared_body", outside);
                        receipt.add("private_high_pcode_instruction_sites", locations);
                        Files.writeString(output.resolve(label + ".pcode.txt"),
                            operations.toString(), StandardCharsets.UTF_8);
                    }
                }
                results.add(receipt);
                Files.writeString(output.resolve("results.private.json"),
                    new GsonBuilder().setPrettyPrinting().create().toJson(results) + "\n");
            }
        } finally { decompiler.dispose(); }
        JsonObject cohort = new JsonObject();
        cohort.addProperty("private_scope_sha256", sha(Files.readAllBytes(config)));
        cohort.addProperty("prepared_source_sha256", currentProgram.getExecutableSHA256());
        cohort.addProperty("language", currentProgram.getLanguageID().toString());
        cohort.addProperty("compiler_spec", currentProgram.getCompilerSpec().getCompilerSpecID().toString());
        cohort.addProperty("original_execution", false);
        cohort.addProperty("whole_program_autoanalysis", false);
        cohort.add("selected_results", results);
        Files.writeString(output.resolve("cohort.private.json"),
            new GsonBuilder().setPrettyPrinting().create().toJson(cohort) + "\n");
        println("Selected static decompilation finished; detailed output is private.");
    }
}
