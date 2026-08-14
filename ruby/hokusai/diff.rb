module Hokusai
  # Internal: Represents a patch to move a loop item
  #           from one location to another
  #           used in [Diff](/api/Hokusai/Diff)
  class MovePatch
    attr_accessor :from, :to, :value, :delete

    # Internal: MovePatch constructor
    # 
    # from: - kwarg index moving from
    # to: - kwarg index moving to
    # value: - kwarg value
    # delete: - should we overwrite to:?
    # 
    def initialize(from:, to:, value:, delete: false)
      @from = from
      @to = to
      @value = value
      @delete = delete
    end
  end

  # Internal: Represents a patch to insert an item into the loop list
  #           used in [Diff](/api/Hokusai/Diff)
  class InsertPatch
    attr_accessor :target, :value, :delete

    # Internal: InsertPatch constructor
    # 
    # target: - kwarg index to insert at
    # value: - kwarg value
    # delete: - should we overwrite the target?
    def initialize(target:, value:, delete: false)
      @target = target
      @value = value
      @delete = delete
    end
  end

  # Internal: Represents a patch to update the value of a loop item at an index
  #           used in [Diff](/api/Hokusai/Diff)
  class UpdatePatch
    attr_accessor :target, :value

    # Internal: constructor
    # 
    # target: - index to update
    # value: - value to update with
    def initialize(target:, value:)
      @target = target
      @value = value
    end
  end

  # Internal: Patch to delete a loop list item
  #           used in [Diff](/api/Hokusai/Diff)
  class DeletePatch
    attr_accessor :target

    # Internal: constructor
    # 
    # target - index to delete
    def initialize(target)
      @target = target
    end
  end

  # Internal: A Differ for comparing one set of values to another
  #           When #patch is called, will yield various patches to
  #           true up the old values with the new values.
  #           see: [MovePatch](/api/Hokusai/MovePatch), [InsertPatch](/api/Hokusai/InsertPatch), [UpdatePatch](/api/Hokusai/UpdatePatch), and [DeletePatch](/api/Hokusai/DeletePatch)
  class Diff
    attr_reader :before, :after, :insertions

    # Internal: constructor
    # 
    # before - array of before values
    # after - array of after values
    # 
    def initialize(before, after)
      @before = before
      @after = after
      @insertions = {}
    end

    def map(list)
      memo = {}
      list.each_with_index do |(key, value), index|
        memo[key] = { value: value, index: index }
      end

      memo
    end

    # Internal: yields a sequence of patches to make 
    #           before the same as after
    #
    # Returns nothing
    def patch
      i = 0
      deletions = 0
      mapbefore = map(before)
      mapafter = map(after)

      while i < after.size
        # left            right
        # [d, a, c]     [(c), e, a, b]
        #
        # 1. [c, a]     [c, (e), a]
        #
        # 2. [c, e, a]   [c, e, b, (a),]
        #
        # 3. [c, e, b, a]
        #
        # is value (c) in left?
        # yes ->
        #   is left[0] (a) in right?
        #     yes -> move c to 0, move a to 2
        #     no -> delete a, move c to 0
        #
        akey, value = after[i]              # b
        ckey, current = before[i] || nil    # a

        if bi = mapbefore.delete(akey) # 2
          if bi[:index] != i              # true (2 != 0)
            if mapafter[ckey] # true
              # move a to 2
              before[bi[:index]] = [ckey, current] # before[2] = a
              # update index
              mapbefore[ckey] = { index: bi[:index], value: current }

              # move c to 0
              yield MovePatch.new(from: bi[:index], to: i, value: bi[:value])
            else
              yield MovePatch.new(from: bi[:index], to: i, value: bi[:value], delete: true)
              mapbefore[ckey] = nil
              deletions += 1
              # next
            end
          elsif value != current
            yield UpdatePatch.new(target: i, value: value)
          end
        else # insert logic
          if mapafter[ckey]
            before[i + 1] = [ckey, current]
            mapbefore[ckey] = { index: i + 1, value: current }

            yield InsertPatch.new(target: i, value: value)
          else
            yield InsertPatch.new(target: i, value: value, delete: true)
            mapbefore[ckey] = nil

          end
        end

        i += 1
      end

      mapbefore.values.each do |value|
        next if value.nil?

        yield DeletePatch.new(value[:index]) unless value[:index].nil?
      end
    end
  end
end