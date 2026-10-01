#ifndef INKEPT_TYPST_H
#define INKEPT_TYPST_H

#include <stddef.h>
#include <stdint.h>

/// A drawn Typst block: premultiplied RGBA pixels, or an error message.
typedef struct {
    uint8_t *pixels;
    size_t length;
    uint32_t width;
    uint32_t height;
    char *error;
} InkeptTypstImage;

/// Sets up the fonts and the folder of offline `@preview` packages. Call once, before rendering.
void inkept_typst_configure(const char *packages_dir, const char *const *font_paths, size_t font_count);

/// Compiles a block of Typst and draws it at `scale` pixels per point, trimmed to the ink.
/// `root` is the folder relative paths are read from; it may be NULL.
InkeptTypstImage inkept_typst_render(const char *source, const char *root, float scale);

/// Releases what `inkept_typst_render` returned.
void inkept_typst_free(InkeptTypstImage image);

#endif
