require_relative 'wishlist_manager'
require_relative 'order_manager'

class Dashboard

  def wm
    @wm ||= WishlistManager.instance.populate_all
  end

  def om
    @om ||= OrderManager.instance.populate_all
  end

  def generate
    wm.data.map do |wishlist|
      [wishlist, list_items[wishlist.id], ordered_items[wishlist.id]]
    end
  end

  def list_items
    Hash[wm.data.map do |wishlist|
      [wishlist.id, wishlist.items.sum(&:qty)]
    end]
  end

  def ordered_items
    ordered_items = Hash[om.grouped_items.map { |item| [item.name, item.qty] }]
    ordered_qty = Hash.new(0)

    wm.data.each do |wishlist|
      wishlist.items.each do |item|
        tested_item = ordered_items[item.name]
        bought_qty =
          if tested_item && tested_item > 0
            if item.qty > tested_item
              tested_item
            else
              item.qty
            end
          end

        if bought_qty
          ordered_qty[wishlist.id] += bought_qty
          ordered_items[item.name] -= bought_qty
        end
      end
    end

    ordered_qty
  end

  def generate_sheet_dashboard
    wm.data.each_with_index do |wishlist, i|
      sheet.add_row [
        wishlist.raw_name,
        "=SUMIF(Items!$A:$A,$A#{i+2},Items!$E:$E)",
        "=SUMIF(Items!$A:$A,$A#{i+2},Items!$K:$K)",
        "=SUMIF(Items!$A:$A,$A#{i+2},Items!$M:$M)",
        "=SUMIF(Items!$A:$A,$A#{i+2},Items!$N:$N)",
        "=D#{i+2}-E#{i+2}"
      ]
    end
  end
end
