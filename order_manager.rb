require 'singleton'
require 'caxlsx'

require_relative 'base_list_manager'
require_relative 'order'
require_relative 'item'

class OrderManager < BaseListManager
  include Singleton

  def valid_statuses
    ['Processed', 'Payment Received', 'Shipped']
  end

  def data
    @data ||=
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

  def populate_items(order_id)
    return if by_id(order_id).items.any?

    order_items = brick_owl.order_items(order_id)
    by_id(order_id).items =
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
end
