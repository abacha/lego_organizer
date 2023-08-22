require 'singleton'
require 'caxlsx'

require_relative 'brick_owl'
require_relative 'order'
require_relative 'item'

class OrderManager
  include Singleton

  def brick_owl
    @brick_owl ||= BrickOwl.new
  end

  def flush
    brick_owl.cache.flush_all
    @orders = nil
  end

  def valid_statuses
    ['Processed', 'Payment Received', 'Shipped']
  end

  def orders
    @orders ||=
      brick_owl.orders.map do |order|
        next unless valid_statuses.include? order[:status]
        details = brick_owl.order_details(order[:order_id])
        Order.new(
          order[:order_id],
          order[:order_date],
          order[:status],
          order[:url],
          details[:tracking_number],
        )
      end.compact
  end

  def order(id)
    orders.detect { |order| order.id == id.to_s }
  end

  def populate_all
    orders.each { |order| populate_items(order.id) }
  end

  def populate_items(order_id)
    return if order(order_id).items.any?

    order_items = brick_owl.order_items(order_id)
    order(order_id).items =
      order_items.map do |order_item|
        Item.new(
          order_item[:boid],
          nil,
          order_item[:type],
          nil,
          order_item[:ordered_quantity].to_i,
          order_item[:color_name],
          CGI::unescapeHTML(order_item[:name]),
          order_item[:image_small],
          nil
        )
      end
  end

  def grouped_items
    orders.each { |order| populate_items(order.id) }
    items = orders.map(&:items).flatten

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
