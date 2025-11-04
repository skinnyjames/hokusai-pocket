module Hokusai
  class PainterEntry
    attr_reader :block, :parent, :x, :y, :w, :h
    def initialize(block, x, y, w, h)
      @block = block
      @x = x
      @y = y
      @w = w
      @h = h
    end
  end

  class CursorState
    attr_accessor :set

    def initialize
      @set = false
    end
  end

  ZTARGET_ROOT = "root"
  ZTARGET_PARENT = "parent"

  class Painter
    attr_reader :root, :input, :before_render, :after_render,
                :events

    def initialize(root, input)
      state = CursorState.new

      @root = root
      @input = input
      @events = {
        hover: HoverEvent.new(input, state),
        wheel: WheelEvent.new(input, state),
        click: ClickEvent.new(input, state),
        mousemove: MouseMoveEvent.new(input, state),
        mouseout: MouseOutEvent.new(input, state),
        mouseup: MouseUpEvent.new(input, state),
        mousedown: MouseDownEvent.new(input, state),
        keyup: KeyUpEvent.new(input, state),
        keypress: KeyPressEvent.new(input, state)
      }

      add_touch_events(events, input, state) unless input.touch.nil?
    end

    def add_touch_events(events, input, state)
      events.merge!({
        taphold: TapHoldEvent.new(input, state),
        pinch: PinchEvent.new(input, state),
        swipe: SwipeEvent.new(input, state),
      })
    end

    def on_before_render(&block)
      @before_render = block
    end

    def on_after_render(&block)
      @after_render = block
    end

    # def debug(parent, children)
    #   @i ||= 0
      
    #   pp [
    #     "#{@i}",
    #     "parent: #{parent.block.class}##{parent.block.node.portal&.ast&.id} (z: #{parent.block.node.meta.get_prop(:z)})",
    #     "children: #{children.map {|c| "#{c.block.class}##{c.block.node.portal&.ast&.id} (z: #{c.block.node.meta.get_prop(:z)})"} }"
    #   ]
    #   @i += 1
    # end

    # @return [Array(Commands::Base)] the command list
    def render(canvas, resize = false, capture: true)
      return if root.children.empty?

      zindexed = {}
      zindex_counter = 0

      zroot_x = canvas.x
      zroot_y = canvas.y
      zroot_w = canvas.width
      zroot_h = canvas.height

      @root.on_resize(canvas) if resize

      before_render&.call([root, nil], canvas, input)

      root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure(root_children, canvas)]

      mouse_y = input.mouse.pos.y
      can_capture = mouse_y >= (canvas.y || 0.0) && mouse_y <= (canvas.y || 0.0) + canvas.height

      hovered = false
      while payload = groups.pop
        group_parent, group_children = payload
        
        parent_z = group_parent.block.node.meta.get_prop(:z)&.to_i
        zindex_counter -= 1 if (parent_z || 0) > 0 && group_children.empty?

        while group = group_children.shift
          z = group.block.node.meta.get_prop(:z)&.to_i || 0
          ztarget = group.block.node.meta.get_prop(:ztarget)

          if (zindex_counter > 0 || z > 0)
            pos = group.block.node.meta.get_prop(:zposition)
            pos = pos.nil? ? Hokusai::Boundary.default : Hokusai::Boundary.convert(pos)

            case ztarget
            when ZTARGET_ROOT
              entry = PainterEntry.new(group.block, (zroot_x || 0.0) + pos.left, (zroot_y || 0.0) + pos.top, zroot_w + pos.right, zroot_h + pos.bottom).freeze
            when ZTARGET_PARENT
              entry = PainterEntry.new(group.block, (group_parent.x || 0.0) + pos.left, (group_parent.y || 0.0) + pos.top, group_parent.w + pos.right, group_parent.h + pos.bottom).freeze
            else
              entry = PainterEntry.new(group.block, group.x + pos.left, group.y + pos.top, group.w + pos.right, group.h + pos.bottom).freeze
            end
          else
            entry = PainterEntry.new(group.block, group.x, group.y, group.w, group.h).freeze
          end


          canvas.reset(entry.x, entry.y, entry.w, entry.h)

          before_render&.call([group.block, group.parent], canvas, input)

          # defer capture for zindexed items so they can stop propagation.
          if capture && (zindex_counter.zero? && z.zero?)
            capture_events(group.block, canvas, hovered: hovered)
          # since evented styles happens during capture and z-index skips capture, well add some
          elsif capture && input.hovered?(canvas)
            if target = group.block.node.meta.target
              group.block.node.add_evented_styles(target.class, "hover")
            end
          end

          if resize
            group.block.on_resize(canvas)
          end

          breaked = false

          group.block.render(canvas) do |local_canvas|
            local_children = (local_canvas.reverse? ? group.block.children?&.reverse : group.block.children?)

            unless local_children.nil?
              groups << [group_parent, group_children]
              parent = PainterEntry.new(group.block, canvas.x, canvas.y, canvas.width, canvas.height)
              groups << [parent, measure(local_children, local_canvas)]

              breaked = true
            else
              breaked = false
            end
          end
          
          if z > 0
            zindex_counter += 1
            # puts ["start (#{z}) <#{parent_z}> {#{zindex_counter}} #{group.block.class}".colorize(:blue), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter] ||= []
            zindexed[zindex_counter] << group
          elsif zindex_counter > 0
            zindexed[zindex_counter] ||= []
            # puts ["push (#{z}) <#{parent_z}>  {#{zindex_counter}} initial #{group.block.class}".colorize(:red), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter] << group
          else
            # puts ["draw (#{z}) <#{parent_z}>  {#{zindex_counter}} #{group.block.class}".colorize(:yellow), z, group.block.node.portal&.ast&.id]
            group.block.execute_draw
          end


          break if breaked
        end
      end

      zindexed.sort.each do |z, groups|
        groups.each do |group|
          canvas.reset(group.x, group.y, group.w, group.h)
          capture_events(group.block, canvas)
          group.block.execute_draw
        end
      end

      if capture
        events[:hover].bubble
        events[:wheel].bubble
        events[:click].bubble
        events[:keyup].bubble
        events[:keypress].bubble
        events[:mousemove].bubble
        events[:mouseout].bubble
        events[:mousedown].bubble
        events[:mouseup].bubble

        unless input.touch.nil?
          events[:taphold].bubble
          events[:pinch].bubble
          events[:swipe].bubble
        end
      end

      after_render&.call
    end

    def measure(children, canvas)
      x = canvas.x || 0.0
      y = canvas.y || 0.0
      width = canvas.width
      height = canvas.height
      vertical = canvas.vertical

      count = 0
      wcount = 0
      hcount = 0
      wsum = 0.0
      hsum = 0.0

      children.each do |block|
        z = block.node.meta.get_prop?(:z)&.to_i || 0
        h = block.node.meta.get_prop?(:height)&.to_f
        w = block.node.meta.get_prop?(:width)&.to_f

        next if z > 0

        if w
          wsum += w
          wcount = wcount.succ
        end

        if h
          hsum += h
          hcount = hcount.succ
        end

        count = count.succ
      end

      neww = width
      newh = height

      if vertical
        c = (count - hcount)
        newh = (newh - hsum)  / (c.zero? ? 1 : c)
      else
        c = (count - wcount)
        neww = (neww - wsum) / (c.zero? ? 1 : c)
      end

      entries = []

      children.each do |block|
        # nw, nh = ntuple
        w = block.node.meta.get_prop?(:width)&.to_f || neww
        h = block.node.meta.get_prop?(:height)&.to_f || newh

        # local_canvas = Hokusai::Canvas.new(w, h, x, y)
        # block.node.meta.props[:height] ||= h
        # block.node.meta.props[:width] ||= w

        entries << PainterEntry.new(block, x, y, w, h).freeze

        if vertical
          y += h
        else
          x += w
        end
      end

      entries
    end

    def capture_events(block, canvas, hovered: false)
      if block.node.portal.nil?
        return
      end

      if input.hovered?(canvas)
        events[:hover].capture(block, canvas)
        events[:click].capture(block, canvas)
        events[:wheel].capture(block, canvas)
        events[:mouseup].capture(block, canvas)
        events[:mousedown].capture(block, canvas)
      else
        events[:mouseout].capture(block, canvas)
      end
      events[:mousemove].capture(block, canvas)

      if input.hovered?(canvas) || block.node.meta.focused || input.keyboard_override
        events[:keyup].capture(block, canvas)
        events[:keypress].capture(block, canvas)
      end

      unless input.touch.nil?
        events[:taphold].capture(block, canvas)
        events[:pinch].capture(block, canvas)
        events[:swipe].capture(block, canvas)
      end
    end
  end
end
