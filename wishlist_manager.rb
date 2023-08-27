require 'singleton'

require_relative 'brick_owl'
require_relative 'wishlist'
require_relative 'base_list_manager'
require_relative 'item'

class WishlistManager < BaseListManager
  def data
    @data ||=
      brick_owl.wishlists.map do |wishlist|
        next unless wishlist[:name].match(/\d{3,4}/)

        Wishlist.new(
          wishlist[:wishlist_id],
          wishlist[:name],
          wishlist[:url],
          wishlist[:item_count],
          wishlist[:lot_count]
        )
      end.compact.sort_by(&:type)
  end

  def populate_items(wishlist_id)
    wishlist = by_id(wishlist_id)
    return if wishlist.items.any?

    lots = brick_owl.wishlist_lots(wishlist_id)
    boids = lots.map { |lot| lot[:boid] }
    catalog_items = brick_owl.catalog_lookup(boids)
    wishlist.items =
      lots.map do |lot|
        catalog_item = catalog_items[lot[:boid].to_sym]
        Item.build(lot, catalog_item)
      end
  end
end
