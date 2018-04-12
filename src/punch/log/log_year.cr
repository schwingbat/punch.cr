module Logger
  def for_year(start : Time, *, project : String | Nil = nil)
    puts "Logging year #{start.year}"
  end
end
