package com.personal.aihub;
import java.io.File;
public class ToolsCheck { public static void main(String[] a) throws Exception {
  JobRun.Act act = new JobRun.Act(new File(a[0], "files"));
  File root = new File(act.getFilesDir(), "forge");
  System.out.println(new PreviewTools(act, root).request(new org.json.JSONObject()).toString(1));
  System.exit(0);
}}
