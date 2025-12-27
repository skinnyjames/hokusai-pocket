class DiffTest < Hokusai::Test
  
  def patches(before, after)
    patches = []

    Hokusai::Diff.new(before, after).patch do |item|
      patches << item
    end

    patches
  end

  test "inserts new items" do
    list = patches([], [[:key1, 1],[:key2, 2],[:key3, 3]])

    expect(list.count).to eql(3)
    
    list.each_with_index do |patch, i|
      expect(patch.class).to eql(Hokusai::InsertPatch)
      expect(patch.target).to eql(i)
      expect(patch.value).to eql(i+1)
      expect(patch.delete).to be(true)
    end
  end

  test "inserts new items and deletes old items" do
    list = patches(
      [[:key1, 1], [:key2, 2], [:key3, 3]],
      [[:key1, 1], [:key4, 4], [:key3, 3]]
    )

    expect(list.count).to eql(1)

    # removes key2 and inserts key4 with 1 insertpatch
    expect(list.first.class).to eql(Hokusai::InsertPatch)
    expect(list.first.target).to eql(1)
    expect(list.first.value).to eql(4)
    expect(list.first.delete).to be(true)
  end

  test "updates items with new values on existing keys" do
    list = patches(
      [[:key1, 1], [:key2, 2], [:key3, 3]],
      [[:key1, 1], [:key2, 4], [:key3, 3]]
    )

    expect(list.count).to eql(1)

    # removes key2 and inserts key4 with 1 insertpatch
    expect(list.first.class).to eql(Hokusai::UpdatePatch)
    expect(list.first.target).to eql(1)
    expect(list.first.value).to eql(4)
  end

  test "moves items that have the same key and no longer are in the list" do
    list = patches(
      [[:key1, 1], [:key2, 2], [:key3, 3]],
      [[:key1, 1], [:key3, 3]]
    )

    expect(list.count).to eql(1)
    expect(list.first.class).to eql(Hokusai::MovePatch)
    expect(list.first.from).to eql(2)
    expect(list.first.to).to eql(1)
    expect(list.first.value).to eql(3)
    expect(list.first.delete).to be(true)
  end

  test "deletes items that have different keys and no longer are in the list" do
    list = patches(
      [[:key1, 1], [:key2, 2], [:key3, 3]],
      [[:key2, 2], [:key3, 3]]
    )

    expect(list.count).to eql(3)
    # moves position 1 to 0
    expect(list[0].class).to eql(Hokusai::MovePatch)
    expect(list[0].from).to eql(1)
    expect(list[0].to).to eql(0)
    expect(list[0].delete).to be(true)

    # moves position 2 to 1
    expect(list[1].class).to eql(Hokusai::MovePatch)
    expect(list[1].from).to eql(2)
    expect(list[1].to).to eql(1)

    # delete position 2
    expect(list[2].class).to eql(Hokusai::DeletePatch)
    expect(list[2].target).to eql(2)
  end

  test "moves items around" do 
    # [d, a, c]     [(c), e, a, b]
    list = patches(
      [[:key1, :d], [:key2, :a], [:key3, :c]],
      [[:key3, :c], [:key4, :e], [:key2, :a], [:key5, :b]]
    )

    expect(list.count).to eql(3)

    # Moves [key3, c] to position 0 and deletes [key1, d]
    expect(list[0].class).to eql(Hokusai::MovePatch)
    expect(list[0].from).to eql(2)
    expect(list[0].to).to eql(0)
    expect(list[0].delete).to eql(true)

    # Inserts [key4, e] into position 1
    expect(list[1].class).to eql(Hokusai::InsertPatch)
    expect(list[1].target).to eql(1)
    expect(list[1].value).to eql(:e)
    expect(list[1].delete).to be(false)

    expect(list[2].class).to eql(Hokusai::InsertPatch)
    expect(list[2].target).to eql(3)
    expect(list[2].value).to eql(:b)
    expect(list[2].delete).to eql(true) # delete doesn't need to be true here...
  end
end