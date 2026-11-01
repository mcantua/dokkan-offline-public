use idevice::{
    IdeviceService, RsdService,
    afc::AfcClient,
    installation_proxy::InstallationProxyClient,
    provider::{IdeviceProvider, RsdProvider},
    rsd::RsdHandshake,
};
use plist_macro::plist;
use rootcause::option_ext::OptionExt;
use rootcause::prelude::*;

use crate::SideloadError as Error;
use std::pin::Pin;
use std::{future::Future, io::{self, Read}, path::Path};
use tokio::io::{AsyncWrite, AsyncWriteExt};

const AFC_UPLOAD_CHUNK_SIZE: usize = if cfg!(target_arch = "wasm32") {
    8 * 1024
} else {
    1024 * 1024
};

/// Installs an ***already signed*** app onto your device.
/// To sign and install an app, see [`crate::sideload::sideload_app`]
pub async fn install_app(
    provider: &impl IdeviceProvider,
    app_path: &Path,
    progress_callback: impl Fn(u64) + Send + Sync,
) -> Result<(), Report> {
    let mut afc_client = AfcClient::connect(provider)
        .await
        .map_err(Error::IdeviceError)?;

    let dir = format!(
        "PublicStaging/{}",
        app_path.file_name().ok_or_report()?.to_string_lossy()
    );
    let total_size = get_dir_size(app_path).unwrap_or(1) as f64;
    let mut uploaded = 0;
    let cb = |progress: f64| {
        progress_callback((progress * 70.0) as u64);
    };
    afc_upload_dir(
        &mut afc_client,
        app_path,
        &dir,
        &cb,
        &mut uploaded,
        total_size,
    )
    .await?;

    let mut instproxy_client = InstallationProxyClient::connect(provider)
        .await
        .map_err(Error::IdeviceError)?;

    let options = plist!(dict {
        "PackageType": "Developer"
    });

    instproxy_client
        .install_with_callback(
            dir,
            Some(plist::Value::Dictionary(options)),
            async |(percentage, _)| {
                progress_callback((70.0 + 0.3 * percentage as f64) as u64);
            },
            (),
        )
        .await
        .map_err(Error::IdeviceError)?;

    Ok(())
}

/// Installs an ***already signed*** app onto your device.
/// To sign and install an app, see [`crate::sideload::sideload_app`]
pub async fn install_app_rsd(
    provider: &mut impl RsdProvider,
    handshake: &mut RsdHandshake,
    app_path: &Path,
    progress_callback: impl Fn(u64) + Send + Sync,
) -> Result<(), Report> {
    let mut afc_client = AfcClient::connect_rsd(provider, handshake)
        .await
        .map_err(Error::IdeviceError)?;

    let dir = format!(
        "PublicStaging/{}",
        app_path.file_name().ok_or_report()?.to_string_lossy()
    );
    let total_size = get_dir_size(app_path).unwrap_or(1) as f64;
    let mut uploaded = 0;
    let cb = |pct: f64| {
        progress_callback((pct * 70.0) as u64);
    };
    afc_upload_dir(
        &mut afc_client,
        app_path,
        &dir,
        &cb,
        &mut uploaded,
        total_size,
    )
    .await?;

    let mut instproxy_client = InstallationProxyClient::connect_rsd(provider, handshake)
        .await
        .map_err(Error::IdeviceError)?;

    let options = plist!(dict {
        "PackageType": "Developer"
    });

    instproxy_client
        .install_with_callback(
            dir,
            Some(plist::Value::Dictionary(options)),
            async |(percentage, _)| {
                progress_callback((70.0 + 0.3 * percentage as f64) as u64);
            },
            (),
        )
        .await
        .map_err(Error::IdeviceError)?;

    Ok(())
}

fn get_dir_size(path: &Path) -> Result<u64, Report> {
    let mut size = 0;
    for entry in isideload_vfs::fs::read_dir(path)? {
        let entry = entry?;
        let path = entry.path();
        let meta = isideload_vfs::fs::metadata(&path)?;
        if meta.is_dir() {
            size += get_dir_size(&path)?;
        } else {
            size += meta.len();
        }
    }
    Ok(size)
}

/// Move the same bounded buffer and VFS reader through the blocking pool. A
/// native disk read must not block the async executor, and cancellation must
/// never leave a task reading/allocating an entire app resource in the background.
async fn read_upload_chunk<R: Read + Send + 'static>(
    mut reader: R,
    mut buffer: Vec<u8>,
    limit: usize,
) -> io::Result<(R, Vec<u8>, usize)> {
    let read = move || {
        let count = loop {
            match reader.read(&mut buffer[..limit]) {
                Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
                result => break result?,
            }
        };
        Ok((reader, buffer, count))
    };
    #[cfg(not(target_arch = "wasm32"))]
    {
        tokio::task::spawn_blocking(read).await.map_err(|_| {
            io::Error::other("App upload source read could not finish")
        })?
    }
    #[cfg(target_arch = "wasm32")]
    {
        // WASM uses the configured in-memory VFS, with no native blocking pool.
        read()
    }
}

/// Shared production copy loop for AFC uploads. Read only after the previous
/// write is acknowledged, retain one buffer regardless of file size, and never
/// treat a shortened/growing source as a successfully uploaded original file.
async fn upload_reader<R: Read + Send + 'static, W: AsyncWrite + Unpin + Send>(
    mut reader: R,
    expected: u64,
    writer: &mut W,
    cb: &(dyn Fn(f64) + Send + Sync),
    uploaded: &mut u64,
    total: f64,
) -> Result<(), Report> {
    let mut buffer = vec![0u8; AFC_UPLOAD_CHUNK_SIZE];
    let mut copied = 0u64;
    loop {
        // Probe once at the declared EOF, without uploading an unexpected byte.
        let limit = (expected - copied).min(AFC_UPLOAD_CHUNK_SIZE as u64).max(1) as usize;
        let count;
        (reader, buffer, count) = read_upload_chunk(reader, buffer, limit).await?;
        if copied == expected {
            if count != 0 {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "App upload source grew").into());
            }
            return Ok(());
        }
        if count == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "App upload source was shortened").into());
        }
        writer.write_all(&buffer[..count]).await?;
        copied += count as u64;
        *uploaded += count as u64;
        cb(*uploaded as f64 / total.max(1.0));
    }
}

fn afc_upload_dir<'a>(
    afc_client: &'a mut AfcClient,
    path: &'a Path,
    afc_path: &'a str,
    cb: &'a (dyn Fn(f64) + Send + Sync),
    uploaded: &'a mut u64,
    total: f64,
) -> Pin<Box<dyn Future<Output = Result<(), Report>> + Send + 'a>> {
    Box::pin(async move {
        let entries = isideload_vfs::fs::read_dir(path)?;
        afc_client
            .mk_dir(afc_path)
            .await
            .map_err(Error::IdeviceError)?;

        for entry in entries {
            let entry = entry?;
            let path = entry.path();
            if isideload_vfs::fs::metadata(&path)?.is_dir() {
                let new_afc_path = format!(
                    "{}/{}",
                    afc_path,
                    path.file_name().ok_or_report()?.to_string_lossy()
                );
                afc_upload_dir(afc_client, &path, &new_afc_path, cb, uploaded, total).await?;
            } else {
                let metadata = isideload_vfs::fs::symlink_metadata(&path)?;
                if !metadata.is_file() || metadata.is_symlink() {
                    return Err(io::Error::new(io::ErrorKind::InvalidInput, "App upload source is not a regular file").into());
                }
                // Keep VFS semantics (including browser in-memory files) instead
                // of bypassing them with a native-only filesystem open.
                let source = isideload_vfs::fs::File::open(&path)?;
                let expected = source.metadata()?.len();
                let mut file_handle = afc_client
                    .open(
                        format!(
                            "{}/{}",
                            afc_path,
                            path.file_name().ok_or_report()?.to_string_lossy()
                        ),
                        idevice::afc::opcode::AfcFopenMode::WrOnly,
                    )
                    .await
                    .map_err(Error::IdeviceError)?;

                upload_reader(source, expected, &mut file_handle, cb, uploaded, total).await?;
                file_handle.close().await.map_err(Error::IdeviceError)?;
            }
        }
        Ok(())
    })
}

#[cfg(test)]
mod uploader_tests {
    use super::*;
    use std::{
        sync::{Arc, Mutex},
        task::{Context, Poll},
        time::Duration,
    };

    #[derive(Default)]
    struct Observed {
        reads: usize,
        buffer: Option<usize>,
        largest_read: usize,
        written: u64,
        largest_write: usize,
        blocked_writes: usize,
        reader_drops: usize,
        writer_drops: usize,
    }
    struct Source {
        state: Arc<Mutex<Observed>>,
        position: u64,
        length: u64,
        max_read: usize,
        fail_after: Option<u64>,
        interrupt_once: bool,
    }
    fn byte(position: u64) -> u8 { (position % 251) as u8 }
    impl Read for Source {
        fn read(&mut self, output: &mut [u8]) -> io::Result<usize> {
            let mut state = self.state.lock().unwrap();
            state.reads += 1;
            state.largest_read = state.largest_read.max(output.len());
            if let Some(address) = state.buffer {
                assert_eq!(address, output.as_ptr() as usize, "Reuse one read allocation");
            } else {
                state.buffer = Some(output.as_ptr() as usize);
            }
            if self.interrupt_once {
                self.interrupt_once = false;
                return Err(io::ErrorKind::Interrupted.into());
            }
            if self.fail_after.is_some_and(|limit| self.position >= limit) {
                return Err(io::Error::other("Synthetic source failure"));
            }
            let count = output.len().min(self.max_read).min((self.length-self.position) as usize);
            for (offset, value) in output[..count].iter_mut().enumerate() {
                *value = byte(self.position + offset as u64);
            }
            self.position += count as u64;
            Ok(count)
        }
    }
    impl Drop for Source {
        fn drop(&mut self) { self.state.lock().unwrap().reader_drops += 1; }
    }
    struct Sink {
        state: Arc<Mutex<Observed>>,
        fail_after: Option<u64>,
        blocked: bool,
    }
    impl AsyncWrite for Sink {
        fn poll_write(self: Pin<&mut Self>, _: &mut Context<'_>, input: &[u8]) -> Poll<io::Result<usize>> {
            let mut state = self.state.lock().unwrap();
            state.largest_write = state.largest_write.max(input.len());
            if self.blocked {
                state.blocked_writes += 1;
                return Poll::Pending;
            }
            if self.fail_after.is_some_and(|limit| state.written >= limit) {
                return Poll::Ready(Err(io::Error::other("Synthetic AFC write failure")));
            }
            // Independent partial-write sink checks every byte, without ever
            // collecting a second file-sized output allocation.
            let count = input.len().min(8191);
            for (offset, &value) in input[..count].iter().enumerate() {
                assert_eq!(value, byte(state.written + offset as u64));
            }
            state.written += count as u64;
            Poll::Ready(Ok(count))
        }
        fn poll_flush(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<io::Result<()>> { Poll::Ready(Ok(())) }
        fn poll_shutdown(self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<io::Result<()>> { Poll::Ready(Ok(())) }
    }
    impl Drop for Sink {
        fn drop(&mut self) { self.state.lock().unwrap().writer_drops += 1; }
    }
    fn fixtures(length: u64) -> (Arc<Mutex<Observed>>, Source, Sink) {
        let state = Arc::new(Mutex::new(Observed::default()));
        let source = Source { state: state.clone(), position: 0, length, max_read: AFC_UPLOAD_CHUNK_SIZE/3+17, fail_after: None, interrupt_once: true };
        let sink = Sink { state: state.clone(), fail_after: None, blocked: false };
        (state, source, sink)
    }
    fn run(future: impl Future<Output=()>) {
        tokio::runtime::Builder::new_current_thread().enable_all().build().unwrap().block_on(future)
    }

    #[test]
    fn uploader_streaming_bounded_partial_reads_writes_and_exact_progress() {
        run(async {
            let length = (AFC_UPLOAD_CHUNK_SIZE*3+19) as u64;
            let (state, source, mut sink) = fixtures(length);
            let progress = Mutex::new(Vec::new());
            let callback = |value| progress.lock().unwrap().push(value);
            let mut uploaded = 23;
            upload_reader(source, length, &mut sink, &callback, &mut uploaded, (length+23) as f64).await.unwrap();
            assert_eq!(uploaded, length+23);
            let observations = state.lock().unwrap();
            assert_eq!(observations.written, length);
            assert!(observations.reads > 4, "Partial source reads must span multiple iterations");
            assert!(observations.largest_read <= AFC_UPLOAD_CHUNK_SIZE);
            assert!(observations.largest_write <= AFC_UPLOAD_CHUNK_SIZE);
            assert_eq!(observations.reader_drops, 1);
            let progress = progress.lock().unwrap();
            assert!(progress.windows(2).all(|pair| pair[0] < pair[1]));
            assert_eq!(*progress.last().unwrap(), 1.0);
            drop(observations);
            drop(sink);
            // Zero-byte resources still verify EOF and issue no AFC write.
            let (state, source, mut sink) = fixtures(0);
            upload_reader(source, 0, &mut sink, &|_| panic!("Empty source made progress"), &mut 0, 0.0).await.unwrap();
            assert_eq!(state.lock().unwrap().written, 0);
        });
    }

    #[test]
    fn uploader_streaming_errors_eof_and_cancel_do_not_read_ahead_or_confirm() {
        run(async {
            let expected = (AFC_UPLOAD_CHUNK_SIZE*2+19) as u64;
            for case in ["read_error", "short", "grown", "write_error"] {
                let actual = match case { "short" => expected-100, "grown" => expected+100, _ => expected };
                let (state, mut source, mut sink) = fixtures(actual);
                if case == "read_error" { source.fail_after = Some((AFC_UPLOAD_CHUNK_SIZE/2) as u64); }
                if case == "write_error" { sink.fail_after = Some((AFC_UPLOAD_CHUNK_SIZE/2) as u64); }
                let mut uploaded = 0;
                assert!(upload_reader(source, expected, &mut sink, &|_| {}, &mut uploaded, expected as f64).await.is_err(), "{case}");
                let state = state.lock().unwrap();
                assert_eq!(state.reader_drops, 1, "{case}");
                assert!(state.written <= expected, "Never send a grown source's extra bytes");
                assert!(uploaded <= state.written, "Only acknowledged complete chunks advance progress");
                if case != "grown" { assert!(uploaded < expected, "{case}"); }
            }
            let (state, source, mut sink) = fixtures(expected);
            sink.blocked = true;
            let task = tokio::spawn(async move {
                upload_reader(source, expected, &mut sink, &|_| panic!("Unacknowledged write advanced progress"), &mut 0, expected as f64).await
            });
            tokio::time::timeout(Duration::from_secs(2), async {
                loop {
                    if state.lock().unwrap().blocked_writes > 0 { break; }
                    tokio::task::yield_now().await;
                }
            }).await.unwrap();
            let reads = state.lock().unwrap().reads;
            for _ in 0..10 { tokio::task::yield_now().await; }
            assert_eq!(state.lock().unwrap().reads, reads, "Backpressure forbids reading ahead");
            task.abort();
            assert!(task.await.unwrap_err().is_cancelled());
            let state = state.lock().unwrap();
            assert_eq!(state.reader_drops, 1);
            assert_eq!(state.writer_drops, 1);
            assert_eq!(state.written, 0);
            assert_eq!(state.reads, reads, "Cancellation cannot leave a source-draining task");
        });
    }
}
