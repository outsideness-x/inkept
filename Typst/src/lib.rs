//! Typst for inkept's notes.
//!
//! The app hands over a block of Typst and gets back a picture: premultiplied RGBA pixels, trimmed
//! to what was drawn. Everything is offline — fonts are built in, and packages come from a folder
//! of `@preview` packages shipped inside the app.

use std::collections::HashMap;
use std::ffi::{c_char, CStr, CString};
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use typst::diag::{FileError, FileResult, PackageError, Severity};
use typst::foundations::{Bytes, Datetime, Duration};
use typst::syntax::{FileId, RootedPath, Source, VirtualPath, VirtualRoot};
use typst::text::{Font, FontBook};
use typst::utils::{LazyHash, Scalar};
use typst::{Library, LibraryExt, World};
use typst_layout::PagedDocument;

/// What the app shares between compilations: the standard library, the fonts and the packages.
struct Shared {
    library: LazyHash<Library>,
    book: LazyHash<FontBook>,
    fonts: Vec<Font>,
    packages: Option<PathBuf>,
}

static SHARED: OnceLock<Mutex<Option<Shared>>> = OnceLock::new();

fn shared() -> &'static Mutex<Option<Shared>> {
    SHARED.get_or_init(|| Mutex::new(None))
}

impl Shared {
    fn new(packages: Option<PathBuf>, extra_fonts: &[PathBuf]) -> Self {
        let mut fonts: Vec<Font> = typst_assets::fonts()
            .flat_map(|data| Font::iter(Bytes::new(data)))
            .collect();
        for path in extra_fonts {
            if let Ok(data) = std::fs::read(path) {
                fonts.extend(Font::iter(Bytes::new(data)));
            }
        }
        Self {
            library: LazyHash::new(Library::default()),
            book: LazyHash::new(FontBook::from_fonts(&fonts)),
            fonts,
            packages,
        }
    }
}

/// One compilation: the block being drawn, and the folder its relative paths start from.
struct Job<'a> {
    shared: &'a Shared,
    main: Source,
    root: Option<PathBuf>,
    files: Mutex<HashMap<FileId, Bytes>>,
}

impl Job<'_> {
    fn path(&self, id: FileId) -> FileResult<PathBuf> {
        let rooted: &RootedPath = &id;
        let base = match rooted.root() {
            VirtualRoot::Project => self.root.clone().ok_or(FileError::AccessDenied)?,
            VirtualRoot::Package(spec) => {
                let packages = self.shared.packages.as_ref().ok_or_else(|| {
                    FileError::Package(PackageError::NotFound(spec.clone()))
                })?;
                let dir = packages
                    .join(spec.namespace.as_str())
                    .join(spec.name.as_str())
                    .join(spec.version.to_string());
                if !dir.is_dir() {
                    return Err(FileError::Package(PackageError::NotFound(spec.clone())));
                }
                dir
            }
        };
        rooted
            .vpath()
            .realize(&base)
            .map_err(|_| FileError::AccessDenied)
    }

    fn read(&self, id: FileId) -> FileResult<Bytes> {
        if let Some(bytes) = self.files.lock().unwrap().get(&id) {
            return Ok(bytes.clone());
        }
        let path = self.path(id)?;
        let data = std::fs::read(&path).map_err(|err| FileError::from_io(err, &path))?;
        let bytes = Bytes::new(data);
        self.files.lock().unwrap().insert(id, bytes.clone());
        Ok(bytes)
    }
}

impl World for Job<'_> {
    fn library(&self) -> &LazyHash<Library> {
        &self.shared.library
    }

    fn book(&self) -> &LazyHash<FontBook> {
        &self.shared.book
    }

    fn main(&self) -> FileId {
        self.main.id()
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.main.id() {
            return Ok(self.main.clone());
        }
        let bytes = self.read(id)?;
        let text = std::str::from_utf8(&bytes).map_err(|_| FileError::InvalidUtf8)?;
        Ok(Source::new(id, text.into()))
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        if id == self.main.id() {
            return Ok(Bytes::from_string(self.main.text().to_string()));
        }
        self.read(id)
    }

    fn font(&self, index: usize) -> Option<Font> {
        self.shared.fonts.get(index).cloned()
    }

    fn today(&self, offset: Option<Duration>) -> Option<Datetime> {
        let seconds = SystemTime::now().duration_since(UNIX_EPOCH).ok()?.as_secs() as i64;
        let offset = offset.map(|duration| duration.seconds() as i64).unwrap_or(0);
        let days = (seconds + offset).div_euclid(86_400);
        let (year, month, day) = civil_from_days(days);
        Datetime::from_ymd(year, month, day)
    }
}

/// Days since 1970-01-01 to a calendar date (Howard Hinnant's algorithm).
fn civil_from_days(days: i64) -> (i32, u8, u8) {
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + if month <= 2 { 1 } else { 0 };
    (year as i32, month as u8, day as u8)
}

/// A drawn block: its pixels, or why it couldn't be drawn.
pub struct Picture {
    pub pixels: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

/// Compiles `source` and draws it at `scale` pixels per point, trimmed to the ink.
pub fn render(source: &str, root: Option<&Path>, scale: f32) -> Result<Picture, String> {
    let guard = shared().lock().unwrap();
    let shared = guard.as_ref().ok_or("typst isn't configured")?;
    let main_id = RootedPath::new(VirtualRoot::Project, VirtualPath::new("/inkept-block.typ").unwrap()).intern();
    let job = Job {
        shared,
        main: Source::new(main_id, source.to_string()),
        root: root.map(Path::to_path_buf),
        files: Mutex::new(HashMap::new()),
    };

    let result = typst::compile::<PagedDocument>(&job);
    let document = result.output.map_err(|diagnostics| {
        diagnostics
            .iter()
            .filter(|diagnostic| diagnostic.severity == Severity::Error)
            .map(|diagnostic| {
                let mut message = diagnostic.message.to_string();
                for hint in &diagnostic.hints {
                    message.push_str("\nhint: ");
                    message.push_str(&hint.v);
                }
                message
            })
            .collect::<Vec<_>>()
            .join("\n")
    })?;

    let options = typst_render::RenderOptions {
        pixel_per_pt: Scalar::new(scale as f64),
        render_bleed: false,
    };
    let pixmap = typst_render::render_merged(
        &document,
        &options,
        typst::layout::Abs::pt(12.0),
        None,
    );
    typst::comemo::evict(20);
    Ok(trim(pixmap, (2.0 * scale) as u32))
}

/// Cuts away the empty page around what was drawn, keeping a small margin.
fn trim(pixmap: tiny_skia::Pixmap, margin: u32) -> Picture {
    let width = pixmap.width();
    let height = pixmap.height();
    let data = pixmap.data();
    let (mut min_x, mut min_y, mut max_x, mut max_y) = (width, height, 0u32, 0u32);
    for y in 0..height {
        let row = (y * width * 4) as usize;
        for x in 0..width {
            if data[row + (x * 4) as usize + 3] != 0 {
                min_x = min_x.min(x);
                max_x = max_x.max(x);
                min_y = min_y.min(y);
                max_y = max_y.max(y);
            }
        }
    }
    if min_x > max_x || min_y > max_y {
        return Picture { pixels: vec![0; 4], width: 1, height: 1 };
    }
    let left = min_x.saturating_sub(margin);
    let top = min_y.saturating_sub(margin);
    let right = (max_x + margin).min(width - 1);
    let bottom = (max_y + margin).min(height - 1);
    let crop_width = right - left + 1;
    let crop_height = bottom - top + 1;
    let mut pixels = Vec::with_capacity((crop_width * crop_height * 4) as usize);
    for y in top..=bottom {
        let start = ((y * width + left) * 4) as usize;
        pixels.extend_from_slice(&data[start..start + (crop_width * 4) as usize]);
    }
    Picture { pixels, width: crop_width, height: crop_height }
}

// MARK: - C interface

/// The result of `inkept_typst_render`. Free it with `inkept_typst_free`.
#[repr(C)]
pub struct InkeptTypstImage {
    /// Premultiplied RGBA, row by row; null when `error` is set.
    pub pixels: *mut u8,
    pub length: usize,
    pub width: u32,
    pub height: u32,
    /// A UTF-8 message when the block couldn't be drawn.
    pub error: *mut c_char,
}

unsafe fn path_from(pointer: *const c_char) -> Option<PathBuf> {
    if pointer.is_null() {
        return None;
    }
    let text = unsafe { CStr::from_ptr(pointer) }.to_str().ok()?;
    (!text.is_empty()).then(|| PathBuf::from(text))
}

/// Sets up the fonts and the offline packages. `font_paths` is a list of `font_count` file paths.
///
/// # Safety
/// Every pointer must be null or point to a NUL-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn inkept_typst_configure(
    packages_dir: *const c_char,
    font_paths: *const *const c_char,
    font_count: usize,
) {
    let packages = unsafe { path_from(packages_dir) };
    let mut fonts = Vec::new();
    if !font_paths.is_null() {
        for index in 0..font_count {
            if let Some(path) = unsafe { path_from(*font_paths.add(index)) } {
                fonts.push(path);
            }
        }
    }
    let configured = Shared::new(packages, &fonts);
    *shared().lock().unwrap() = Some(configured);
}

/// Draws a block of Typst. `root` is the folder relative paths (like images) are read from.
///
/// # Safety
/// `source` must point to a NUL-terminated UTF-8 string; `root` must be null or one.
#[no_mangle]
pub unsafe extern "C" fn inkept_typst_render(
    source: *const c_char,
    root: *const c_char,
    scale: f32,
) -> InkeptTypstImage {
    let empty = InkeptTypstImage {
        pixels: std::ptr::null_mut(),
        length: 0,
        width: 0,
        height: 0,
        error: std::ptr::null_mut(),
    };
    let text = match unsafe { CStr::from_ptr(source) }.to_str() {
        Ok(text) => text,
        Err(_) => return InkeptTypstImage { error: message("the block isn't valid UTF-8"), ..empty },
    };
    let root = unsafe { path_from(root) };
    let outcome = std::panic::catch_unwind(|| render(text, root.as_deref(), scale.max(0.5)));
    match outcome {
        Ok(Ok(picture)) => {
            let mut pixels = picture.pixels.into_boxed_slice();
            let length = pixels.len();
            let pointer = pixels.as_mut_ptr();
            std::mem::forget(pixels);
            InkeptTypstImage { pixels: pointer, length, width: picture.width, height: picture.height, error: std::ptr::null_mut() }
        }
        Ok(Err(error)) => InkeptTypstImage { error: message(&error), ..empty },
        Err(_) => InkeptTypstImage { error: message("typst stopped unexpectedly"), ..empty },
    }
}

/// Releases what `inkept_typst_render` returned.
///
/// # Safety
/// `image` must come from `inkept_typst_render` and be freed once.
#[no_mangle]
pub unsafe extern "C" fn inkept_typst_free(image: InkeptTypstImage) {
    if !image.pixels.is_null() {
        drop(unsafe { Box::from_raw(std::ptr::slice_from_raw_parts_mut(image.pixels, image.length)) });
    }
    if !image.error.is_null() {
        drop(unsafe { CString::from_raw(image.error) });
    }
}

fn message(text: &str) -> *mut c_char {
    CString::new(text.replace('\0', " ")).unwrap_or_default().into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn configure() {
        unsafe { inkept_typst_configure(std::ptr::null(), std::ptr::null(), 0) };
    }

    #[test]
    fn draws_math_and_trims_the_page() {
        configure();
        let picture = render("#set page(width: 300pt, height: auto, margin: 0pt, fill: none)\n$ integral_0^1 x^2 dif x = 1/3 $", None, 2.0).unwrap();
        assert!(picture.width > 20 && picture.width < 600);
        assert!(picture.height > 10);
        assert_eq!(picture.pixels.len(), (picture.width * picture.height * 4) as usize);
    }

    #[test]
    fn reports_errors() {
        configure();
        let error = render("#undefined-function()", None, 2.0).err().unwrap();
        assert!(error.contains("unknown variable"), "{error}");
    }

    #[test]
    fn dates_are_civil() {
        assert_eq!(civil_from_days(0), (1970, 1, 1));
        assert_eq!(civil_from_days(20_720), (2026, 9, 24));
    }
}
