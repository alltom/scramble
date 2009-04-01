require "set"

class Board
  include Enumerable
  
  def initialize rows, cols
    @rows = rows
    @cols = cols
    @cells = (0..(rows * cols)-1).map { |i|
      Cell.new "#{(i/cols)+1}/#{(i%cols)+1}"
    }
    define_neighbors
  end
  
  def parse string
    letters = string.gsub(/[\r\n\t ]/, '').gsub(//, " ").gsub("q u", "qu").split(" ")
    each do |cell|
      cell.letter = letters.shift
    end
  end
  
  def each
    @cells.each do |cell|
      yield cell
    end
  end
  
  # zero-indexed
  def cell(row, col)
    return unless (0..@rows-1).include? row
    return unless (0..@cols-1).include? col
    @cells[row*@cols + col]
  end
  
  private
  
  def define_neighbors
    (0..@rows-1).each do |row|
      (0..@cols-1).each do |col|
        c = cell(row, col)
        c.add_neighbor cell(row-1, col-1)
        c.add_neighbor cell(row-1, col)
        c.add_neighbor cell(row-1, col+1)
        c.add_neighbor cell(row, col-1)
        c.add_neighbor cell(row, col+1)
        c.add_neighbor cell(row+1, col-1)
        c.add_neighbor cell(row+1, col)
        c.add_neighbor cell(row+1, col+1)
      end
    end
  end
end

class Cell
  attr_reader :letter
  
  def initialize name
    @name = name
    @neighbors = Set.new
  end
  
  def letter=(value)
    return unless /[abcdefghijklmnopqrstuvwxyz]+/i =~ value
    @letter = value
  end
  
  def add_neighbor cell
    @neighbors << cell if cell
  end
  
  def neighbors
    @neighbors
  end
  
  def find_words wordstub, used_cells = []
    cells = []
    wordstub.next_letters.each do |letter|
      cells = cells | (neighbors.find_all { |cell| cell.letter == letter })
    end
    cells -= used_cells
    words = []
    words << wordstub.word if wordstub.is_word?
    words | (cells.map { |cell| cell.find_words(wordstub.next(cell.letter), used_cells + [self]) }.flatten)
  end
  
  def to_s
    @name
  end
  
  def inspect
    "<Cell #{to_s}>"
  end
end

class WordStub
  attr_reader :word
  
  def initialize word
    @word = word
    @hash = dict_hash
  end
  
  # load from a file of words
  def self.from_dict filename, length_range
    dict = WordStub.new ""
    File.readlines(filename).each do |word|
      next unless length_range.include? word.chomp.length
      stub = dict
      word.chomp.gsub(//, " ").gsub("q u", "qu").split(" ").each do |letter|
        stub = stub.next(letter.downcase)
      end
      stub.next(".") # mark end of word
    end
    dict
  end
  
  def next letter
    @hash[letter]
  end
  
  def next_letters
    @hash.keys
  end
  
  def to_s
    word
  end
  
  def is_word?
    @hash.keys.include? "."
  end
  
  private
  
  def dict_hash
    return Hash.new { |hash, letter| hash[letter] = WordStub.new(word + letter) }
  end
end

b = Board.new 4, 4
b.parse "
  o t s o
  g r e k
  n g l s
  o s e r
"

d = WordStub.from_dict "/usr/share/dict/web2", (3..8)
words = []
b.each do |cell|
  words = words | cell.find_words(d.next(cell.letter))
end
puts words.sort_by { |w| w.length }
