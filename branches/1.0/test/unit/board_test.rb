require File.dirname(__FILE__) + '/../test_helper'

class BoardTest < ActiveSupport::TestCase
  def setup
    @rook = Piece.new(:rook, :white )
    @white_king, @white_queen = [ Piece.new(:king, :white), Piece.new(:queen, :white) ]
    @black_king, @black_queen = [ Piece.new(:king, :black), Piece.new(:queen, :black) ]

    @initial_board = Board.initial_board    
    @lone_rook_board = Board[ :a1 => @rook ]
    @kings_and_queens= Board[ :d1 => @white_queen, :e1 => @white_king, :d8 => @black_queen, :e8 => @black_king ]
  end
  
  # Replace this with your real tests.
  def test_board_can_store_a_piece
    assert_equal :rook, @lone_rook_board[:a1].role
  end

  def test_board_can_move_piece_when_none_other_on_board # :nodoc:
    piece_moved = @lone_rook_board.move!( Move.new( :from_coord => :a1, :to_coord => :a4) )
    assert_equal @rook, piece_moved
    assert_nil @lone_rook_board[:a1]
  end
  
  def test_board_can_consider_move_and_revert # :nodoc:
    assert_equal @rook, @lone_rook_board[:a1]
    
    @lone_rook_board.consider_move( Move.new( :from_coord => :a1, :to_coord => :a8) ) do
      assert_nil @lone_rook_board[:a1]
      assert_equal @rook, @lone_rook_board[:a8]
    end
    
    assert_equal @rook, @lone_rook_board[:a1]
  end
  
  def test_can_capture_a_piece_on_board_by_moving_onto_its_square
    @kings_and_queens.move!( Move.new( :from_coord => :d8, :to_coord => :d1) )  #daring Queen capture
    assert_equal 3, @kings_and_queens.squares_occupied.length
    assert_equal :black, @kings_and_queens[:d1].side
  end

  def test_capture_is_undone_when_only_considering # :nodoc:
    @kings_and_queens.consider_move( Move.new( :from_coord => :d8, :to_coord => :d1 ) )  do
      assert_equal 3, @kings_and_queens.squares_occupied.length
      assert_equal :black, @kings_and_queens[:d1].side
    end
    assert_equal 4, @kings_and_queens.squares_occupied.length
    assert_equal :white, @kings_and_queens[:d1].side
        
  end
  
  def test_32_pieces_on_initial_board
    assert_equal 32, @initial_board.pieces.length
  end
  
  def test_white_king_is_on_e1
    assert_equal :king,  @initial_board[:e1].role
    assert_equal :white, @initial_board[:e1].side
  end

  def test_white_queen_is_on_d1
    assert_equal :queen, @initial_board[:d1].role
    assert_equal :white, @initial_board[:d1].side
  end
  
  def test_black_king_is_on_e8
    assert_equal :king,  @initial_board[:e8].role
    assert_equal :black, @initial_board[:e8].side
  end
  
  def test_king_has_no_moves_on_initial_board
    white_king = @initial_board[:e1]
    assert_equal 0, @initial_board.allowed_moves(:e1).length
  end
  
  def test_knight_has_two_moves_on_initial_board
    k = @initial_board[:b8]
    moves = @initial_board.allowed_moves(:b8)
    assert_equal 2, moves.length
  end
  
  def test_pawn_may_move_two_squares_on_initial_board
    p = @initial_board[:c7]
    moves = @initial_board.allowed_moves(:c7)
    assert_equal 2, moves.length
  end
  
  def test_piece_can_capture_by_landing_on_opposing_square
    board = Board[ :c6 => Piece.new(:knight, :black, :kings), :d4 => Piece.new(:pawn, :white, :d) ]
    
    moves = board.allowed_moves(:c6)
    assert moves.include?(:d4)
    board.move!( Move.new( :from_coord => :c6, :to_coord => :d4 ) )
    assert_equal :knight, board[:d4].role
  end
  
  def test_pawn_may_move_diagonally_only_if_capturing
    board = Board[ :d4 => Piece.new(:pawn, :white, :d), :e5 => Piece.new(:pawn, :black, :e) ]
    moves = board.allowed_moves(:d4)
    assert moves.include?(:e5)
    board.move!( Move.new( :from_coord => :d4, :to_coord => :e5) )  
    assert_equal :white, board[:e5].side
    
    #now there is not another piece to capture - he should only have one move
    assert_equal 1, board.allowed_moves(:e5).length
  end

  def test_if_capture_coordinate_included_that_piece_will_be_deleted_upon_replay
    board = Board[ :d5 => Piece.new(:pawn, :white, :d), :c5 => Piece.new(:pawn, :black, :c) ]
    board.move!( Move.new( :from_coord => :d5, :to_coord => :c6, :capture_coord => :e5) )  
    assert_nil board[:e5]
  end

  def test_pawn_can_capture_en_passant
    #TODO technically if the pawn being captured has not been moved exactly once this should be forbidden but im ignoring that for now since it requires knowledge of the move list-  ditto for castling as well
    board = Board[ :d5 => Piece.new(:pawn, :white, :d), :c5 => Piece.new(:pawn, :black, :c) ]
    moves = board.allowed_moves(:d5)
    assert ! moves.include?(:c6)
  end
  
end