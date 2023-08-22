require 'singleton'

require_relative 'brick_owl'
require_relative 'base_list_manager'
require_relative 'wishlist'
require_relative 'item'

class CollectionManager < BaseListManager
  LIST_ID = 1845863

  def data
    @data ||=
      brick_owl.wishlist_lots(LIST_ID).map do |set|
        boid = set[:boid]
        set_number = set[:ids].detect { |id| id[:type] == "set_number" }[:id].gsub(/-1/, '')
        url = "https://brickowl.com/catalog/#{boid}"
        Wishlist.new(boid, set_number, url)
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
        catalog_item = catalog_items[lot[:boid].to_sym]
        Item.build(lot, catalog_item)
      end
  end
end
