module Currency
  private def self.add_separators(value : String, separator = ",")
    count = 0
    values = [] of String

    dollars, cents = value.split(".")

    dollars.split("").reverse.each_with_index do |c, i|
      values << separator if i % 3 == 0 && i != 0
      values << c
    end

    values.reverse.join("") + "." + cents
  end

  def self.to_usd(amount : Float)
    to_usd((amount * 100).to_i32)
  end

  def self.to_usd(cents : Int)
    "$" + add_separators("%.2f" % (cents / 100.0), ",")
  end
end
