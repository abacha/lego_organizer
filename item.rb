class Item < Struct.new(:boid, :item_number, :type, :category, :qty, :color, :name, :image, :url)
  def initialize(*)
    super
    self.name.gsub!('LEGO ', '') if name
    self.qty ||= 0
  end

  def self.build(catalog_item, lot = nil)
    image = catalog_item[:images].any? ? catalog_item[:images][0][:small] : nil
    item_number = catalog_item[:ids].detect { |id_type| id_type[:type] == 'item_no' }
    new(
      catalog_item[:boid],
      item_number ? item_number[:id] : nil,
      item_type(catalog_item),
      catalog_item[:cat_name_path],
      lot ? (lot[:qty] || lot[:quantity]).to_i : nil,
      catalog_item[:color_name],
      catalog_item[:name].gsub('LEGO ', ''),
      image,
      catalog_item[:url]
    )
  end

  def self.item_type(catalog_item)
    item_name = catalog_item[:name]
    category = catalog_item[:cat_name_path]

    if category.include? 'Minifig'
      'Minifig'
    elsif category.include? 'Animal'
      'Animal'
    elsif item_name.include? 'Sticker'
      'Sticker'
    elsif item_name.include? 'Wheel Rim'
      'Wheel'
    elsif item_name.include? 'Tire'
      'Tire'
    elsif item_name.include? 'String'
      'String'
    else
      'Part'
    end
  end
end
