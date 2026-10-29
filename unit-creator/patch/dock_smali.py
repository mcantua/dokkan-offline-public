"""Smali hooks in CreatorActivity for the in-app animation player and offline pictures."""
import sys, re, pathlib
root = pathlib.Path(sys.argv[1]) / "smali/com/personal/aihub"

def patch(name, old, new, count=1):
    p = root / name; s = p.read_text()
    if s.count(old) != count: sys.exit(f"{name}: expected {count} match(es), found {s.count(old)}")
    p.write_text(s.replace(old, new))

# 1. Previews open in the in-app player; PreviewActivity stays as the fallback.
patch("CreatorActivity.smali",
""".method m16lambda$7$compersonalaihubCreatorActivity(Ljava/lang/String;)V
    .locals 2

""",
""".method m16lambda$7$compersonalaihubCreatorActivity(Ljava/lang/String;)V
    .locals 2

    invoke-static {p0, p1}, Lcom/personal/aihub/ForgeFixes;->openPreview(Landroid/app/Activity;Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :forge_window

    return-void

    :forge_window
""")

# 2. "Save video" picker results reach the in-app player.
patch("CreatorActivity.smali",
"""    invoke-super {p0, p1, p2, p3}, Landroid/app/Activity;->onActivityResult(IILandroid/content/Intent;)V

    const/16 v0, 0x1f5
""",
"""    invoke-super {p0, p1, p2, p3}, Landroid/app/Activity;->onActivityResult(IILandroid/content/Intent;)V

    invoke-static {p0, p1, p2, p3}, Lcom/personal/aihub/ForgeFixes;->activityResult(Landroid/app/Activity;IILandroid/content/Intent;)V

    const/16 v0, 0x1f5
""")

# 3. Saved Eclipse pictures are served from the phone.
patch("CreatorActivity$AnonymousClass1.smali",
""".method public shouldInterceptRequest(Landroid/webkit/WebView;Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
    .locals 10

""",
""".method public shouldInterceptRequest(Landroid/webkit/WebView;Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
    .locals 10

    invoke-static {p2}, Lcom/personal/aihub/ForgeFixes;->intercept(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;

    move-result-object v0

    if-eqz v0, :forge_continue

    return-object v0

    :forge_continue
""")
print("smali hooks applied")

# 4. The app is called Dokkan Unit Creator: user-visible native text no longer says "Forge" or
#    "Dokkan Unit Creation". Internal names (storage folders, bridge names, saved-project format)
#    are unchanged so existing units keep working.
TEXT = [
    ('"This JSON is not a Forge project. Use a SQLite database for game data."', '"This JSON is not a Dokkan Unit Creator project. Use a SQLite database for game data."'),
    ('"ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by Forge."', '"ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by this app."'),
    ('"Invalid embedded Forge project"', '"Invalid embedded unit project"'),
    ('"Dokkan Unit Forge"', '"Dokkan Unit Creator"'),
    ('"Update Forge to load the packaged animation catalog"', '"Update Dokkan Unit Creator to load the packaged animation catalog"'),
    ('"The packaged item scene adapter is incompatible. Update Forge."', '"The packaged item scene adapter is incompatible. Update Dokkan Unit Creator."'),
    ('"The packaged player adapter is incompatible. Update Forge."', '"The packaged player adapter is incompatible. Update Dokkan Unit Creator."'),
    ('"The public player changed. Update Forge before previewing this animation."', '"The public player changed. Update Dokkan Unit Creator before previewing this animation."'),
    ('"The private upload folder is not owned by Forge."', '"The private upload folder is not owned by this app."'),
    ('"There is not enough memory to convert this Eclipse patch. Close previews and try again, or use Forge on a device with more memory."', '"There is not enough memory to convert this Eclipse patch. Close previews and try again, or use a device with more memory."'),
    ('"DokkanUnitForge/2.1"', '"DokkanUnitCreator/2.1"'), ('"DokkanUnitForge/2.3"', '"DokkanUnitCreator/2.3"'),
    ('"DokkanUnitForge/2.5"', '"DokkanUnitCreator/2.5"'), ('"DokkanUnitForge/2.7"', '"DokkanUnitCreator/2.7"'),
    ('"Dokkan Unit Creation startup"', '"Dokkan Unit Creator startup"'),
    ('"How should Dokkan Unit Creation open your AI?"', '"How should Dokkan Unit Creator open your AI?"'),
    ('"Dokkan Unit Creation AI prompt"', '"Dokkan Unit Creator AI prompt"'),
]
count = 0
for path in root.rglob("*.smali"):
    s = path.read_text(); o = s
    for a, b in TEXT: s = s.replace(", " + a, ", " + b)
    s = s.replace("Dokkan Unit Creation opens the official", "Dokkan Unit Creator opens the official").replace("\\n\\nDokkan Unit Creation does not read chats", "\\n\\nDokkan Unit Creator does not read chats")
    if s != o: path.write_text(s); count += 1
print("renamed visible native text in", count, "files")
