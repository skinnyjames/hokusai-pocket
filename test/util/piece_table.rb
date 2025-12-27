class PieceTableTest < Hokusai::Test
  def with_piece_table(initial = "")
    table = Hokusai::Util::PieceTable.new(initial)

    yield table
  end

  test "inserts correctly with no buffer" do
    with_piece_table do |table|
      table.insert("hello", 0)
      table.insert(" ", 5)
      table.insert("world", 6)
      expect(table.to_s).to eql("hello world")
    end
  end

  test "#insert at the start of a string" do
    with_piece_table("hello world") do |table|
      table.insert("ok ", 0)
      expect(table.to_s).to eql("ok hello world")
    end
  end

  test "#insert in the middle of a string" do
    with_piece_table("hello world") do |table|
      table.insert("big ", 6)
      expect(table.to_s).to eql("hello big world")
    end
  end

  test "#insert at the end of a string" do
    with_piece_table("hello world") do |table|
      table.insert(" ok?", 11)
      expect(table.to_s).to eql("hello world ok?")
    end
  end

  test "double insert" do
    with_piece_table("hello world") do |table|
      table.insert(" big", 5)
      table.insert(" again", 5)
      expect(table.to_s).to eql("hello again big world")
    end
  end

  test "delete at the start of a string" do
    with_piece_table("hello world") do |table|
      table.delete(0, 6)
      expect(table.to_s).to eql("world")
    end
  end

  test "delete at the end of a string" do
    with_piece_table("hello world") do |table|
      table.delete(5, 6)
      expect(table.to_s).to eql("hello")
    end
  end

  test "delete in the middle of a string" do
    with_piece_table("hello world") do |table|
      table.delete(5, 1)
      expect(table.to_s).to eql("helloworld")
    end
  end

  test "#insert wrong initial offset" do
    with_piece_table("hello world") do |table|
      begin
        table.insert("boo", 20)
      rescue Hokusai::Error => ex
        expect(ex.message).to match(/Piece table offset is greater than the buffer/)
      end
    end
  end

  test "#delete wrong offset" do
    with_piece_table("hello world") do |table|
      begin
        table.delete(20, 1)
      rescue Hokusai::Error => ex
        expect(ex.message).to match(/Piece table offset is greater than the buffer/)
      end
    end
  end

  test "#delete wrong size" do
    with_piece_table("hello world") do |table|
      begin
        table.delete(5, 20)
      rescue Hokusai::Error => ex
        expect(ex.message).to match(/Piece table offset is greater than the buffer/)
      end
    end
  end
end