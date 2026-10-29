"""Read two pinned original IPA members in Google's cloud; preserve the IPA.

No filesystem mount, executable launch, credential serialization, save access,
or full-IPA copy. Runtime Drive IDs belong in the private notebook config.
"""
import hashlib
import io
import json
import re
import stat
import zipfile


PINS = {
    "Frameworks/AdjustSigSdk.framework/AdjustSigSdk": (
        649088, "564cdec07867697f3e23b8df760a5c3d9c067ff5dec2780dd905c83eaf2f96cd"),
    "database.db": (
        535552, "667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3"),
}
OUTPUT_NAME = "Private-iPhone-startup-inputs.zip"
MAX_READ_BYTES = 16 * 1024 * 1024


def valid_id(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_-]{10,160}", value):
        raise ValueError("Invalid runtime Drive file/folder ID")
    return value


class DriveRangeReader(io.RawIOBase):
    """Bounded, seekable authenticated media reader; rejects ignored ranges."""

    def __init__(self, session, source_id, size):
        self.session, self.source_id, self.size = session, valid_id(source_id), size
        self.position = self.downloaded = 0
        self.cache = {}
        self.block_size = 1024 * 1024

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        position = offset + (self.position if whence == io.SEEK_CUR else
                             self.size if whence == io.SEEK_END else 0)
        if whence not in (io.SEEK_SET, io.SEEK_CUR, io.SEEK_END) or position < 0:
            raise ValueError("Invalid archive seek")
        self.position = position
        return position

    def readinto(self, destination):
        remaining = min(len(destination), max(0, self.size - self.position))
        written = 0
        while written < remaining:
            block = self.position // self.block_size
            if block not in self.cache:
                start = block * self.block_size
                end = min(start + self.block_size, self.size) - 1
                length = end - start + 1
                if self.downloaded + length > MAX_READ_BYTES:
                    raise ValueError("Stopped at the 16 MiB cloud-read limit; original preserved")
                response = self.session.get(
                    "https://www.googleapis.com/drive/v3/files/" + self.source_id,
                    params={"alt": "media"}, headers={"Range": f"bytes={start}-{end}"},
                    timeout=60, stream=True)
                try:
                    if (response.status_code != 206 or
                            response.headers.get("Content-Range") != f"bytes {start}-{end}/{self.size}"):
                        raise ValueError("Drive did not honor bounded media ranges; no full download attempted")
                    data = bytearray()
                    for piece in response.iter_content(65536):
                        data.extend(piece)
                        if len(data) > length:
                            raise ValueError("Oversized Drive range response")
                    if len(data) != length:
                        raise ValueError("Incomplete Drive range response")
                finally:
                    response.close()
                self.downloaded += length
                if len(self.cache) >= 4:
                    self.cache.pop(next(iter(self.cache)))
                self.cache[block] = bytes(data)
            data = self.cache[block]
            offset = self.position % self.block_size
            count = min(len(data) - offset, remaining - written)
            destination[written:written + count] = data[offset:offset + count]
            written += count
            self.position += count
        return written


def extract_archive(reader, source_size):
    """Hash exact allowlisted bytes; do not inspect any other member contents."""
    output = io.BytesIO()
    manifest = {"format": "od-original-startup-inputs-v1", "source_size": source_size,
                "whole_ipa_sha256_reverified": False, "members": []}
    with zipfile.ZipFile(io.BufferedReader(reader)) as source:
        entries = source.infolist()
        roots = {x.filename.split("/")[1] for x in entries
                 if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", x.filename)}
        if len(roots) != 1:
            raise ValueError("Expected one original iPhone application")
        prefix = "Payload/" + roots.pop() + "/"
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as target:
            for relative, (size, digest) in PINS.items():
                matches = [x for x in entries if x.filename == prefix + relative]
                if len(matches) != 1:
                    raise ValueError("An exact startup member is missing or duplicated")
                member = matches[0]
                mode = member.external_attr >> 16
                if (member.is_dir() or stat.S_ISLNK(mode) or member.flag_bits & 1 or
                        member.file_size != size or member.compress_size > size + 65536):
                    raise ValueError("Startup member type/size is inconsistent")
                data = source.read(member)
                if len(data) != size or hashlib.sha256(data).hexdigest() != digest:
                    raise ValueError("Startup member SHA-256 mismatch; original preserved")
                info = zipfile.ZipInfo(relative, date_time=(2026, 10, 29, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (stat.S_IFREG | 0o400) << 16
                target.writestr(info, data)
                manifest["members"].append({"path": relative, "size": size, "sha256": digest})
            info = zipfile.ZipInfo("manifest.json", date_time=(2026, 10, 29, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            target.writestr(info, json.dumps(manifest, sort_keys=True, indent=2) + "\n")
    return output.getvalue(), manifest


def run(source_id, folder_id, expected_size=1144358271):
    """Call after managed Colab authorization; never export its credentials."""
    import google.auth
    from google.auth.transport.requests import AuthorizedSession
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaIoBaseUpload, MediaIoBaseDownload

    valid_id(source_id)
    valid_id(folder_id)
    credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/drive"])
    service = build("drive", "v3", credentials=credentials, cache_discovery=False)
    metadata = service.files().get(fileId=source_id, fields="size,mimeType,trashed").execute()
    if (metadata.get("trashed") or int(metadata.get("size", -1)) != expected_size or
            metadata.get("mimeType", "").startswith("application/vnd.google-apps.")):
        raise ValueError("Original IPA metadata changed; no extraction attempted")
    folder = service.files().get(fileId=folder_id, fields="mimeType,trashed").execute()
    if folder.get("trashed") or folder.get("mimeType") != "application/vnd.google-apps.folder":
        raise ValueError("Configured output is not an existing Drive folder")
    session = AuthorizedSession(credentials)
    reader = DriveRangeReader(session, source_id, expected_size)
    try:
        data, manifest = extract_archive(reader, expected_size)
    finally:
        session.close()
    if len(data) >= 32 * 1024 * 1024:
        raise ValueError("Startup archive exceeded its bounded upload size")
    query = f"'{folder_id}' in parents and trashed=false and name='{OUTPUT_NAME}'"
    existing = service.files().list(q=query, fields="files(id,appProperties),nextPageToken", pageSize=100).execute()
    if existing.get("nextPageToken") or len(existing.get("files", [])) > 1:
        raise ValueError("Duplicate named startup outputs require review; nothing overwritten")
    media = MediaIoBaseUpload(io.BytesIO(data), mimetype="application/zip", resumable=False)
    if existing.get("files"):
        previous = existing["files"][0]
        if (previous["id"] == source_id or
                previous.get("appProperties", {}).get("odStartupInputs") != "v1"):
            raise ValueError("Existing output is not owned by this extractor; original preserved")
        result = service.files().update(fileId=existing["files"][0]["id"], media_body=media,
                                        fields="id,size").execute()
    else:
        result = service.files().create(body={"name": OUTPUT_NAME, "parents": [folder_id],
                                             "appProperties": {"odStartupInputs": "v1"}},
                                        media_body=media, fields="id,size").execute()
    if int(result.get("size", -1)) != len(data):
        raise ValueError("Uploaded startup archive size was not verified")
    verify = io.BytesIO()
    downloader = MediaIoBaseDownload(verify, service.files().get_media(fileId=result["id"]),
                                     chunksize=2 * 1024 * 1024)
    done = False
    while not done:
        _, done = downloader.next_chunk()
        if verify.tell() > len(data):
            raise ValueError("Startup archive verification was oversized")
    digest = hashlib.sha256(data).hexdigest()
    if hashlib.sha256(verify.getvalue()).hexdigest() != digest:
        raise ValueError("Uploaded startup archive SHA-256 verification failed")
    print("Finished: 2 pinned original startup files restored in Google Drive.")
    print("Original IPA unchanged. No Mac copy, app build, or game launch performed.")
    print("Cloud IPA bytes read:", reader.downloaded, "Archive bytes:", len(data))
    print("Archive SHA-256:", digest)
    print("Output: https://drive.google.com/file/d/" + result["id"] + "/view")
    return {"id": result["id"], "size": len(data), "sha256": digest,
            "cloud_source_bytes_read": reader.downloaded, "manifest": manifest}
