module Hokusai
  class TexturePainter
    attr_reader :root, :commands

    def initialize(root)
      @root = root
      @commands = []
    end

    # @return [Array(Commands::Base)] the command list
    def render(canvas)
      return if root.children.empty?

      zindexed = {}
      zindex_counter = 0

      zroot_x = canvas.x
      zroot_y = canvas.y
      zroot_w = canvas.width
      zroot_h = canvas.height

      root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure([root], canvas)]

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
            zindexed[zindex_counter] << group
          else
            commands.concat group.block.node.meta.commands.queue
            group.block.node.meta.commands.clear!
          end

          break if breaked
        end
      end

      zindexed.sort.each do |z, groups|
        groups.each do |group|
          canvas.reset(group.x, group.y, group.w, group.h)

          commands.concat group.block.node.meta.commands.queue
          group.block.node.meta.commands.clear!
        end
      end
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
  end
end
