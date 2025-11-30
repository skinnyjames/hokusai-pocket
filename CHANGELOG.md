# Changelog

## 0.3.3

### Added

* Added `Hokusai::Texture#dup` to duplicate textures
* Added `Hokusai::Rect#merge` to merge rects

## 0.3.2

### Added

* Added licenses for dependencies

### Bugfix

* Support additions from 0.3.1 release in `hokusai-pocket publish` command.

## 0.3.1

### Added

* Added Native dialog handling `Hokusai::on_open_file(opts)` and `Hokusai.on_save_file(opts)`
* Added `blend_mode_begin` and `blend_mode_end` to `Hokusai::Commands`
* Added `Hokusai::open_file`, `Hokusai::save_file`, and `Hokusai::open_files`
* Added `Commands::Texture#rotation=` to set rotation on a texture

### Changed

* Modified `Hokusai.set_window_position` to take positional parameters
* Modified `src/backend.c` to support blend mode commands and file dialog commands
* Modified `Brewfile` to fetch and build https://github.com/mlabbe/nativefiledialog.git

### Bugfix

* Fixed segfault where style parsing on a template pointed to unallocated memory that was later freed
