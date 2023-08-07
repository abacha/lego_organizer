require 'singleton'

require_relative 'brick_owl'
require_relative 'wishlist'
require_relative 'item'

class WishlistManager
  include Singleton

  def brick_owl
    @brick_owl ||= BrickOwl.new
  end

  def flush
    brick_owl.cache.flush_all
    @wishlists = nil
  end

  def wishlists
    @wishlists ||=
      brick_owl.wishlists.map do |wishlist|
        next unless wishlist[:name].match(/\d{3,4}/)

        Wishlist.new(
          *wishlist.values_at(:wishlist_id, :name, :url, :item_count, :lot_count)
        )
      end.compact.sort_by(&:name)
  end

  def wishlist(id)
    wishlists.detect { |wishlist| wishlist.id == id.to_s }
  end

  def populate_all
    wishlists.each { |wishlist| populate_items(wishlist.id) }
  end

  def populate_items(wishlist_id)
    return if wishlist(wishlist_id).items.any?

    lots = brick_owl.wishlist_lots(wishlist_id)
    boids = lots.map { |lot| lot[:boid] }.join(',')
    catalog_items = brick_owl.catalog_lookup(boids)
    wishlist(wishlist_id).items =
      lots.map do |lot|
        catalog_item = catalog_items[:items][lot[:boid].to_sym]
        Item.build(lot, catalog_item)
      end
  end

  def with_item(item)
    wishlists.select do |wishlist|
      wishlist.items.map(&:name).include?(item.name)
    end.map(&:name)
  end

  def grouped_items
    wishlists.each { |wishlist| populate_items(wishlist.id) }
    items = wishlists.map(&:items).flatten

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
