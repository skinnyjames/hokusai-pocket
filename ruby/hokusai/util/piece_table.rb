module Hokusai::Util
  class PieceTable
    attr_accessor :buffer, :buffer_add, :last_piece_index
    attr_reader :pieces

    def initialize(buffer = "")
      @pieces = [[:original, 0, buffer.size]]
      @buffer_add = ""
      @buffer = buffer
      @last_piece_index = nil
    end

    def to_s
      io = ""
      pieces.each do |(which, start, size)|
        case which
        when :original
          io << buffer[start, size]
        else
          if buffer_add[start, size].nil?
            raise Hokusai::Error.new("#{which} Bad: #{start} #{size}")
          end

          io << buffer_add[start, size]
        end
      end

      io
    end

    def insert(text, offset = buffer.size - 1)
      return nil if text.size.zero?

      piece_at_buffer_offset(offset) do |(piece, index, remainder)|
        which, start, size = piece
        length = remainder - start
        
        new_pieces = []
        new_pieces << [which, start, length] if length > 0
        new_pieces << [:add, buffer_add.size, text.size]
        new_pieces << [which, length + start, size - length] if size - length > 0
  
        self.last_piece_index = index + 1
        self.pieces[index..index] = new_pieces
        self.buffer_add += text
      end
    end

    def delete(offset, count)
      piece_at_buffer_offset(offset) do |(piece_left, index_left, remainder_left)|
        piece_at_buffer_offset(offset + count) do |(piece_right, index_right, remainder_right)|
          if index_left == index_right
            if remainder_left == piece_left[1]
              pieces[index_left] = [piece_left[0], piece_left[1] + count, piece_left[2] - count]

              return
            elsif remainder_right == piece_left[1] + piece_left[2]
              pieces[index_left] = [piece_left[0], piece_left[1], piece_left[2] - count]
              
              return
            end
          end
  
          new_pieces = []
          left = [piece_left[0], piece_left[1], remainder_left - piece_left[1]]
          left_condition = (remainder_left - piece_left[1] > 0)
          right = [piece_right[0], remainder_right, piece_right[2] - (remainder_right - piece_right[1])]
          right_condition =  (piece_right[2] - (remainder_right - piece_right[1]) > 0)

          if !left_condition && !right_condition
            new_pieces << left
          end
          
          if left_condition
            new_pieces << left
          end

          if right_condition
            new_pieces << right
          end

          self.pieces[index_left..index_right] = new_pieces
          self.last_piece_index = nil
        end
      end
    end

    private def piece_at_buffer_offset(offset)
      raise Hokusai::Error.new("Piece table offset is negative") if offset.negative?
  
      remainder = offset
  
      pieces.each_with_index do |piece, index|
        if remainder <= piece[2]
          yield([piece, index, remainder + piece[1]])
          
          return
        end
  
        remainder -= piece[2]
      end      

      raise Hokusai::Error.new("Piece table offset is greater than the buffer! #{offset}\n#{pieces}")
    end
  end
end