"""Exporter smoke test using tiny fixtures, not substitute Dokkan game data."""
import base64
import gzip
import json
import pathlib
import shutil
import tempfile
from playwright.sync_api import sync_playwright
from standalone import bundle

HERE = pathlib.Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix=".standalone-test-", dir=HERE) as tmp:
    root = pathlib.Path(tmp)
    site = root / "site-artifact"
    for sub in ("web", "data/db", "fonts", "vendor/media"):
        (site / sub).mkdir(parents=True, exist_ok=True)
    (site / "fonts/test.ttf").write_bytes((HERE.parent / "v2/ui/fonts/RussoOne-Regular.ttf").read_bytes())
    (site / "app.css").write_text('@font-face{font-family:Fixture;src:url("fonts/test.ttf")}#screen{font-family:Fixture}')
    (site / "web/argon2.js").write_text("self.fixtureValue=42;")
    (site / "web/argon2-worker.js").write_text('importScripts("argon2.js"); self.onmessage=()=>self.postMessage(self.fixtureValue);')
    (site / "vendor/media/usm-writer.js").write_text("self.firstImport=19;")
    (site / "vendor/media/native-adx.js").write_text("self.secondImport=23;")
    (site / "vendor/media/instant-worker.js").write_text("importScripts('./usm-writer.js', './native-adx.js'); self.onmessage=()=>postMessage(self.firstImport+self.secondImport);")
    data = base64.b64encode(gzip.compress(json.dumps({"fixture": True}).encode())).decode()
    (site / "data/db/manifest.json.gz.b64.txt").write_text(data)
    (site / "start.js").write_text("window.loadOrder=['start'];")
    (site / "app.js").write_text("""
window.loadOrder.push('app');
window.bodyWasReady=!!document.querySelector('#screen');
window.testDone=(async()=>{
 const r=await fetch(window.__forgeStandaloneBase+'data/db/manifest.json.gz.b64.txt');
 const b=Uint8Array.from(atob(await r.text()),c=>c.charCodeAt(0));
 window.dataResult=JSON.parse(await new Response(new Blob([b]).stream().pipeThrough(new DecompressionStream('gzip'))).text());
 const worker=new Worker(window.__forgeStandaloneBase+'web/argon2-worker.js');
 window.workerResult=await new Promise((resolve,reject)=>{worker.onmessage=e=>resolve(e.data);worker.onerror=reject;worker.postMessage({});});
 worker.terminate();
 const instant=new Worker(new URL('./vendor/media/instant-worker.js',location.href));
 window.instantResult=await new Promise((resolve,reject)=>{instant.onmessage=e=>resolve(e.data);instant.onerror=reject;instant.postMessage({});});
 instant.terminate();
 await document.fonts.load('16px Fixture');
 window.fontLoaded=document.fonts.check('16px Fixture');
 window.missingStatus=(await fetch(window.__forgeStandaloneBase+'missing.json')).status;
 window.fixtureComplete=true;
})();
""")
    (site / "index.html").write_text('<title>Fixture</title><link rel="stylesheet" href="app.css"><script src="start.js"></script><script src="app.js" defer></script><a class="skip-link" href="#screen">Skip</a><main id="screen">Fixture only</main>')
    output = root / "UnitCreator-test.html"
    bundle(site, output, "2.36.2", 'Check </script> & fonts', compression_threshold=0)
    first = output.read_bytes()
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=shutil.which("chromium"))
        page = browser.new_page(viewport={"width": 390, "height": 844})
        errors, remote = [], []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.on("request", lambda r: remote.append(r.url) if r.url.startswith(("https:", "http:")) else None)
        # Fulfill only the one document; adjacent worker URLs must resolve from
        # the embedded map, not an actual server or neighboring files.
        document_url = "http://standalone.test/nested/UnitCreator-test.html"
        page.route("**/*", lambda route: route.fulfill(status=200, content_type="text/html", body=output.read_text()) if route.request.url == document_url else route.abort())
        page.goto(document_url)
        page.wait_for_function("window.fixtureComplete===true", timeout=15000)
        assert page.evaluate("window.loadOrder") == ["start", "app"]
        assert page.evaluate("window.bodyWasReady")
        assert page.evaluate("window.dataResult.fixture")
        assert page.evaluate("window.workerResult") == 42
        assert page.evaluate("window.instantResult") == 42
        assert page.evaluate("window.fontLoaded")
        assert page.evaluate("window.missingStatus") == 404
        assert 'Check </script> & fonts' in page.locator("#test-page-info").inner_text()
        assert not errors, errors
        assert remote == [document_url], remote
        browser.close()
    # Failure must keep the last valid file, and must never leave another copy behind.
    (site / "data/db/manifest.json.gz.b64.txt").unlink()
    try:
        bundle(site, output, "bad", "bad")
        raise AssertionError("Missing game data was accepted")
    except ValueError:
        pass
    assert output.read_bytes() == first
    assert not output.with_suffix(".part").exists()
    print("PASS: embedded scripts/data/font, Argon and current-directory multi-import movie workers, banner escaping, no adjacent/network dependencies, atomic replacement; Safari file:// remains unverified")
