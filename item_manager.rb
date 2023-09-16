require 'singleton'

require_relative 'brick_owl'
class ItemManager
  include Singleton

  def brick_owl
    @brick_owl ||= BrickOwl.new
  end

  def lookup(boid)
    catalog_item = brick_owl.lookup(boid)
    Item.build(catalog_item)
  end
end
