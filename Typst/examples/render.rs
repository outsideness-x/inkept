//! Renders Typst files the way the app does, for checking templates:
//!
//!     cargo run --release --example render -- <packages dir> <out dir> <file.typ>...
//!
//! Each file is set on a 340pt page in the note's ink and written next to <out dir> as a PNG.

use std::ffi::CString;
use std::path::Path;

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let (packages, out, files) = (&args[0], &args[1], &args[2..]);
    let packages = CString::new(packages.as_str()).unwrap();
    let neucha = CString::new(concat!(env!("CARGO_MANIFEST_DIR"), "/../inkept/Resources/Fonts/Neucha.ttf")).unwrap();
    let fonts = [neucha.as_ptr()];
    unsafe { inkept_typst::inkept_typst_configure(packages.as_ptr(), fonts.as_ptr(), fonts.len()) };
    let prelude = "#set page(width: 340pt, height: auto, margin: (x: 2pt, y: 4pt), fill: none)\n\
        #set text(font: (\"Neucha\", \"New Computer Modern\"), size: 17pt, fill: rgb(\"#1d1b19\"))\n\
        #show math.equation: set text(font: \"New Computer Modern Math\")\n";
    for file in files {
        let source = std::fs::read_to_string(file).unwrap();
        let started = std::time::Instant::now();
        match inkept_typst::render(&format!("{prelude}{source}"), None, 2.0) {
            Ok(picture) => {
                let name = Path::new(file).file_stem().unwrap().to_string_lossy();
                let parent = Path::new(file).parent().and_then(|p| p.file_name()).map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
                let target = Path::new(out).join(format!("{parent}-{name}.png"));
                let mut pixmap = tiny_skia::Pixmap::new(picture.width, picture.height).unwrap();
                pixmap.data_mut().copy_from_slice(&picture.pixels);
                pixmap.save_png(&target).unwrap();
                println!("ok    {file} {}x{} in {:?}", picture.width, picture.height, started.elapsed());
            }
            Err(error) => println!("ERROR {file}: {error}"),
        }
    }
}
