require 'singleton'

require_relative 'brick_owl'
require_relative 'base_list_manager'
require_relative 'wishlist'
require_relative 'item'

class CollectionManager < BaseListManager
  LIST_ID = 1845863

  def data
    @data ||=
      begin
        lots = brick_owl.wishlist_lots(LIST_ID)
        boids = lots.map { |lot| lot[:boid] }
        catalog = brick_owl.catalog_lookup(boids)

        lots.map do |set|
          boid = set[:boid]
          set_number = set[:ids].detect { |id| id[:type] == "set_number" }[:id].gsub(/-1/, '')
          Wishlist.new(boid, "s#{set_number} - #{catalog[boid.to_sym][:name]}", catalog[:url])
        end
      end
  end

  def populate_items(collection_id)
    collection = by_id(collection_id)
    return if collection.items.any?

    lots = brick_owl.inventory(collection_id)
    boids = lots.map { |lot| lot[:boid] }
    catalog_items = brick_owl.catalog_lookup(boids)
    collection.items =
      lots.map do |lot|
        Item.build(catalog_items[lot[:boid].to_sym], lot)
      end
  end
end
