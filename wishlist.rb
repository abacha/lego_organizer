class Wishlist < Struct.new(:id, :raw_name, :url, :item_count, :lot_count, :items)
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
    "#{SET_IMAGES_URL}/#{set_number}-1.jpg" if set_number
  end

  def set_number
    parsed_name[2] || ''
  end

  def type
    if parsed_name[1] == 'b'
      '(0) Built'
    elsif parsed_name[1] == 'p'
      '(1) Prioritized'
    elsif parsed_name[1] == 'w'
      '(2) Not Priority'
    elsif parsed_name[1] == 'z'
      '(3) Buckets'
    else
      '(4) Other'
    end
  end

  def name
    parsed_name[3] || ''
  end


  def item(item)
    items.detect { |list_item| item.boid == list_item.boid }
  end

  private
  def parsed_name
    raw_name.match(/(\w)(\d{3,4}) - (.*)/) || []
  end
end
