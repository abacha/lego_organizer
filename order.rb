class Order < Struct.new(:id, :date, :status, :url, :tracking_number, :items)

  def initialize(*attrs)
    super
    self.date = Time.at(date.to_i)
    self.items = []
  end
end
