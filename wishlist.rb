class Wishlist < Struct.new(:id, :name, :url, :item_count, :lot_count, :items)
  SET_IMAGES_URL = 'https://images.brickset.com/sets/images'

  def initialize(*attrs)
    super
    self.items = []
  end

  def by_type
    items.inject(Hash.new(0)) { |h, e| h[e.type] += e.qty; h }
  end

  def by_color
    items.inject(Hash.new(0)) { |h, e| h[e.color] += e.qty; h }
  end

  def image_url
    code_set = name.match(/\d{3,4}/)
    "#{SET_IMAGES_URL}/#{code_set[0]}-1.jpg" if code_set
  end
end
