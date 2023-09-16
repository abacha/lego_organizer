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
    data.each { |list| Thread.new { populate_items(list.id) } }.join
    self
  end

  def with_item(item)
    data.select { |list| list.item(item) }
  end

  def intersect(id_1, id_2)
    populate_items(id_1)
    populate_items(id_2)
    by_id(id_1).items.select do |origin|
      by_id(id_2).items.map(&:boid).include? origin.boid
    end
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

