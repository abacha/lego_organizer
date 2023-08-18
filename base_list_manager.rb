require 'singleton'

require_relative 'brick_owl'
require_relative 'item'

class BaseListManager
  include Singleton

  def brick_owl
    @brick_owl ||= BrickOwl.new
  end

  def flush
    brick_owl.cache.flush_all
    @data = nil
  end

  def by_id(id)
    data.detect { |list| list.id == id.to_s }
  end

  def populate_all
    data.each { |list| populate_items(list.id);break }
    self
  end

  def populate_items(list_id)
    return if by_id(list_id).items.any?

    lots = brick_owl.list_lots(list_id)
    boids = lots.map { |lot| lot[:boid] }.join(',')
    catalog_items = brick_owl.catalog_lookup(boids)
    list(list_id).items =
      lots.map do |lot|
        catalog_item = catalog_items[:items][lot[:boid].to_sym]
        Item.build(lot, catalog_item)
      end
  end

  def with_item(item)
    data.select { |list| list.items.map(&:name).include?(item.name) }.
      map(&:name)
  end

  def grouped_items
    populate_all
    items = data.map(&:items).flatten

    items.inject(Hash.new) do |hash, element|
      if hash[element[:name]]
        hash[element[:name]].qty += element.qty
      else
        hash[element[:name]] = element.clone
      end
      hash
    end.values
  end
end

