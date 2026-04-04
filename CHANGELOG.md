# Changelog

## 0.5.0

## Added

* Introduces a DSL for building templates `Hokusai::NodeBuilder`

## Modified

* Moves `Hokusai::Ast` into Ruby space
* Moves event capturing logic inside the components `render` block.

## Removed

* Removes `src/ast/**.c`

## 0.4.6

## Added

* Adds `KeyDownEvent` to Keyboard Events

## Modified

* Changes `Commands::Image` to use slices

## Bugfix

* Fixes bug in `Hokusai::Node` where a prop wouldn't be nilable

## 0.4.5

### Modified

* Fixes build scripts to use working mruby version
* Fixes build scripts for windows

## 0.4.2

### Modified

* Fixes `build_templates.rb` to publish from the correct branch

## 0.4.1

### Added

* Added tests in `tests/`, run with `hokusai-pocket run:target=tests/entrypoint.rb`

### Fixed

* Fixed bug with template directive updates
* Fixed bug with conditional directive 

## 0.4.0

### Added

* Added support for async io via [libuv](https://github.com/libuv/libuv)
* Added `Hokusai::Work` for starting async work and `Hokusai.worker#queue`

### Changed

* Modified `Brewfile` to make loading hokusai more composable
* Adds vendored `libuv.a`
* Changes `<backend.c>` to run a `UV::Loop` inside the draw loop.

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
