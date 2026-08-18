//BEGINSIDEBAR
const sidebar = JSON.parse('[{"link":"api/Hokusai","text":"Hokusai","items":[{"link":"api/Hokusai/Ast","text":"Ast","items":[{"link":"api/Hokusai/Ast/Event","text":"Event"},{"link":"api/Hokusai/Ast/Func","text":"Func"},{"link":"api/Hokusai/Ast/Loop","text":"Loop"},{"link":"api/Hokusai/Ast/Prop","text":"Prop"}]},{"link":"api/Hokusai/Backend","text":"Backend","items":[{"link":"api/Hokusai/Backend/Config","text":"Config"}]},{"link":"api/Hokusai/BaseEvent","text":"BaseEvent"},{"link":"api/Hokusai/Block","text":"Block"},{"link":"api/Hokusai/Blocks","text":"Blocks","items":[{"link":"api/Hokusai/Blocks/Button","text":"Button"},{"link":"api/Hokusai/Blocks/Center","text":"Center"},{"link":"api/Hokusai/Blocks/Checkbox","text":"Checkbox"},{"link":"api/Hokusai/Blocks/Clipped","text":"Clipped"},{"link":"api/Hokusai/Blocks/ColorPicker","text":"ColorPicker"},{"link":"api/Hokusai/Blocks/Cursor","text":"Cursor"},{"link":"api/Hokusai/Blocks/Dropdown","text":"Dropdown"},{"link":"api/Hokusai/Blocks/DropdownItem","text":"DropdownItem"},{"link":"api/Hokusai/Blocks/Dynamic","text":"Dynamic"},{"link":"api/Hokusai/Blocks/Empty","text":"Empty"},{"link":"api/Hokusai/Blocks/Hblock","text":"Hblock"},{"link":"api/Hokusai/Blocks/Icon","text":"Icon"},{"link":"api/Hokusai/Blocks/Label","text":"Label"},{"link":"api/Hokusai/Blocks/Modal","text":"Modal"},{"link":"api/Hokusai/Blocks/Panel","text":"Panel"},{"link":"api/Hokusai/Blocks/PickerCircle","text":"PickerCircle"},{"link":"api/Hokusai/Blocks/Scrollbar","text":"Scrollbar"},{"link":"api/Hokusai/Blocks/Selectable","text":"Selectable"},{"link":"api/Hokusai/Blocks/Slider","text":"Slider"},{"link":"api/Hokusai/Blocks/Titlebar","text":"Titlebar","items":[{"link":"api/Hokusai/Blocks/Titlebar/OSX","text":"OSX"}]},{"link":"api/Hokusai/Blocks/Toggle","text":"Toggle"},{"link":"api/Hokusai/Blocks/Tooltip","text":"Tooltip"},{"link":"api/Hokusai/Blocks/Translation","text":"Translation"},{"link":"api/Hokusai/Blocks/Variable","text":"Variable"},{"link":"api/Hokusai/Blocks/Vblock","text":"Vblock"}]},{"link":"api/Hokusai/Boundary","text":"Boundary"},{"link":"api/Hokusai/Canvas","text":"Canvas"},{"link":"api/Hokusai/ClickEvent","text":"ClickEvent"},{"link":"api/Hokusai/Color","text":"Color"},{"link":"api/Hokusai/Commands","text":"Commands","items":[{"link":"api/Hokusai/Commands/Base","text":"Base"},{"link":"api/Hokusai/Commands/BlendModeBegin","text":"BlendModeBegin"},{"link":"api/Hokusai/Commands/BlendModeEnd","text":"BlendModeEnd"},{"link":"api/Hokusai/Commands/Circle","text":"Circle"},{"link":"api/Hokusai/Commands/Image","text":"Image"},{"link":"api/Hokusai/Commands/Rectangle","text":"Rectangle"},{"link":"api/Hokusai/Commands/RotationBegin","text":"RotationBegin"},{"link":"api/Hokusai/Commands/RotationEnd","text":"RotationEnd"},{"link":"api/Hokusai/Commands/ScaleBegin","text":"ScaleBegin"},{"link":"api/Hokusai/Commands/ScaleEnd","text":"ScaleEnd"},{"link":"api/Hokusai/Commands/ScissorBegin","text":"ScissorBegin"},{"link":"api/Hokusai/Commands/ScissorEnd","text":"ScissorEnd"},{"link":"api/Hokusai/Commands/ShaderBegin","text":"ShaderBegin"},{"link":"api/Hokusai/Commands/ShaderEnd","text":"ShaderEnd"},{"link":"api/Hokusai/Commands/Text","text":"Text"},{"link":"api/Hokusai/Commands/Texture","text":"Texture"},{"link":"api/Hokusai/Commands/TranslationBegin","text":"TranslationBegin"},{"link":"api/Hokusai/Commands/TranslationEnd","text":"TranslationEnd"}]},{"link":"api/Hokusai/CursorState","text":"CursorState"},{"link":"api/Hokusai/DeletePatch","text":"DeletePatch"},{"link":"api/Hokusai/Diff","text":"Diff"},{"link":"api/Hokusai/DoubletapEvent","text":"DoubletapEvent"},{"link":"api/Hokusai/Drag","text":"Drag"},{"link":"api/Hokusai/DragEvent","text":"DragEvent"},{"link":"api/Hokusai/Error","text":"Error"},{"link":"api/Hokusai/FontRegistry","text":"FontRegistry"},{"link":"api/Hokusai/HTTP","text":"HTTP","items":[{"link":"api/Hokusai/HTTP/Response","text":"Response"},{"link":"api/Hokusai/HTTP/ResponseBody","text":"ResponseBody"}]},{"link":"api/Hokusai/HoverEvent","text":"HoverEvent"},{"link":"api/Hokusai/ImageRegistry","text":"ImageRegistry"},{"link":"api/Hokusai/Input","text":"Input"},{"link":"api/Hokusai/InsertPatch","text":"InsertPatch"},{"link":"api/Hokusai/KeyDownEvent","text":"KeyDownEvent"},{"link":"api/Hokusai/KeyPressEvent","text":"KeyPressEvent"},{"link":"api/Hokusai/KeyUpEvent","text":"KeyUpEvent"},{"link":"api/Hokusai/Keyboard","text":"Keyboard"},{"link":"api/Hokusai/KeyboardEvent","text":"KeyboardEvent"},{"link":"api/Hokusai/Meta","text":"Meta"},{"link":"api/Hokusai/Mounting","text":"Mounting","items":[{"link":"api/Hokusai/Mounting/LoopContext","text":"LoopContext"},{"link":"api/Hokusai/Mounting/LoopEntry","text":"LoopEntry"},{"link":"api/Hokusai/Mounting/MountEntry","text":"MountEntry"},{"link":"api/Hokusai/Mounting/UpdateEntry","text":"UpdateEntry"}]},{"link":"api/Hokusai/Mouse","text":"Mouse"},{"link":"api/Hokusai/MouseButton","text":"MouseButton"},{"link":"api/Hokusai/MouseDownEvent","text":"MouseDownEvent"},{"link":"api/Hokusai/MouseEvent","text":"MouseEvent"},{"link":"api/Hokusai/MouseMoveEvent","text":"MouseMoveEvent"},{"link":"api/Hokusai/MouseOutEvent","text":"MouseOutEvent"},{"link":"api/Hokusai/MouseUpEvent","text":"MouseUpEvent"},{"link":"api/Hokusai/MovePatch","text":"MovePatch"},{"link":"api/Hokusai/MusicRegistry","text":"MusicRegistry"},{"link":"api/Hokusai/Node","text":"Node"},{"link":"api/Hokusai/NodeBuilder","text":"NodeBuilder"},{"link":"api/Hokusai/NodeMounter","text":"NodeMounter"},{"link":"api/Hokusai/NodeProxy","text":"NodeProxy"},{"link":"api/Hokusai/Outline","text":"Outline"},{"link":"api/Hokusai/Padding","text":"Padding"},{"link":"api/Hokusai/Painter","text":"Painter"},{"link":"api/Hokusai/PainterEntry","text":"PainterEntry"},{"link":"api/Hokusai/Patches","text":"Patches"},{"link":"api/Hokusai/Pinch","text":"Pinch"},{"link":"api/Hokusai/PinchInEvent","text":"PinchInEvent"},{"link":"api/Hokusai/PinchOutEvent","text":"PinchOutEvent"},{"link":"api/Hokusai/ProxyValue","text":"ProxyValue"},{"link":"api/Hokusai/Publisher","text":"Publisher"},{"link":"api/Hokusai/Rect","text":"Rect"},{"link":"api/Hokusai/Reloader","text":"Reloader"},{"link":"api/Hokusai/SwipeEvent","text":"SwipeEvent"},{"link":"api/Hokusai/TapDownEvent","text":"TapDownEvent"},{"link":"api/Hokusai/TapEvent","text":"TapEvent"},{"link":"api/Hokusai/TapHoldEvent","text":"TapHoldEvent"},{"link":"api/Hokusai/TapReleaseEvent","text":"TapReleaseEvent"},{"link":"api/Hokusai/TapUpEvent","text":"TapUpEvent"},{"link":"api/Hokusai/TexturePainter","text":"TexturePainter"},{"link":"api/Hokusai/TextureRegistry","text":"TextureRegistry"},{"link":"api/Hokusai/Touch","text":"Touch"},{"link":"api/Hokusai/TouchEvent","text":"TouchEvent"},{"link":"api/Hokusai/UpdatePatch","text":"UpdatePatch"},{"link":"api/Hokusai/Util","text":"Util","items":[{"link":"api/Hokusai/Util/GeometrySelection","text":"GeometrySelection"},{"link":"api/Hokusai/Util/PieceTable","text":"PieceTable"},{"link":"api/Hokusai/Util/PositionSelection","text":"PositionSelection"},{"link":"api/Hokusai/Util/Selection","text":"Selection"},{"link":"api/Hokusai/Util/WrapCache","text":"WrapCache"},{"link":"api/Hokusai/Util/WrapCachePayload","text":"WrapCachePayload"},{"link":"api/Hokusai/Util/WrapStream","text":"WrapStream"},{"link":"api/Hokusai/Util/Wrapped","text":"Wrapped"}]},{"link":"api/Hokusai/Vec2","text":"Vec2"},{"link":"api/Hokusai/WheelEvent","text":"WheelEvent"},{"link":"api/Hokusai/Work","text":"Work"}]}]')
//ENDSIDEBAR

const guides = [
  {
    text: "Getting started",
    link: "getting_started.md"
  },
  {
    text: "Application anatomy",
    link: "anatomy.md",
    // items: [
    //   {
    //     text: "State",
    //     link: "anatomy/state.md"
    //   },
    //   {
    //     text: "Templates",
    //   },
    //   {
    //     text: "Drawing API",
    //   },
    //   {
    //     text: "Composability",
    //     items: [
    //       {
    //         text: "Props"
    //       },
    //       {
    //         text: "Emits",
    //       },
    //       {
    //         text: "Provisions",
    //       }
    //     ]
    //   },
    //   {
    //     text: "Lifecycle"
    //   },
    //   {
    //     text: "Networking/Async"
    //   }
    // ]
  },
  {
    text: "Ruby API",
    items: sidebar
  }
]

export default {
  // site-level options
  title: 'hokusai-pocket',
  base: '/hokusai-pocket/',
  description: 'Portable GUIs in Ruby',
  themeConfig: {
    sidebar: guides,
    search: {
      provider: 'local'
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/skinnyjames/hokusai-pocket' },
      { icon: 'discourse', link: 'https://www.rubyforum.org/tag/hokusai-pocket' }
    ]
  }
}