require 'caxlsx'
require 'forwardable'
require_relative 'wishlist_manager'
require_relative 'order_manager'

class Exporter
  extend Forwardable
  def_delegator :@package, :workbook
  attr_reader :package, :styles

  def initialize
    @package = Axlsx::Package.new
    package.use_autowidth = false
    workbook.styles.fonts[0].sz = 9

    @styles = {}

    @styles[:hleft] =
      workbook.styles.add_style alignment: { vertical: :center, horizontal: :left, wrap_text: true }
    @styles[:hcenter] =
      workbook.styles.add_style alignment: { vertical: :center, horizontal: :center, wrap_text: true }
    @styles[:green] =
      workbook.styles.add_style bg_color: 'C6EFCE', color: '006100', type: :dxf
    @styles[:yellow] =
      workbook.styles.add_style bg_color: 'FFEB9C', color: '9C5700', type: :dxf

  end

  def wm
    @wm ||= WishlistManager.instance.populate_all
  end

  def om
    @om ||= OrderManager.instance.populate_all
  end

  def generate_spreadsheet
    FileUtils.rm_f('lego.xlsx')
    generate_sheet_items
    generate_sheet_orders
    generate_sheet_order_items
    generate_sheet_dashboard
    package.use_shared_strings = true
    package.serialize('lego.xlsx')
  end

  def generate_sheet_items
    workbook.add_worksheet(name: 'Items') do |sheet|
      row = sheet.add_row %w[Wishlist Name Code BOID # Color Type Category Picture Link Bought OrderID Remaining Cart],
        style: [
          styles[:hleft],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter],
          styles[:hcenter]
        ]

      0.upto(row.size - 1) { |i| row.cells[i].b = true }

      ordered_items = Hash[om.grouped_items.map { |item| [item.name, item.qty] }]

      i = 0
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
          ordered_items[item.name] -= bought_qty if bought_qty

          sheet.add_row [
            wishlist.raw_name,
            item.name.gsub('LEGO ', ''),
            item.item_number,
            item.boid,
            item.qty,
            item.color,
            item.type,
            item.category,
            "=IMAGE(\"#{item.image}\",,1)",
            "=HYPERLINK(\"#{item.url}\",\"View\")",
            bought_qty,
            "=TEXTJOIN(\" \", TRUE, IF('Order Items'!$E:$E=D#{i+2}, 'Order Items'!$A:$A, \"\"))",
            "=E#{i+2}-K#{i+2}",
            nil
          ], height: 45, style: [
            styles[:hleft],
            styles[:hleft],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
            styles[:hcenter],
          ]
          i += 1
        end
      end
      sheet.column_widths 30, 60, 11, 11, 3, 20, 11, 20, 8, 8, 8, 10, 10, 10
    end
  end

  def generate_sheet_order_items
    workbook.add_worksheet(name: 'Order Items') do |sheet|
      row = sheet.add_row %w[Order Name Type Color BOID Qty], style: styles[:hleft]
      0.upto(row.size - 1) { |i| row.cells[i].b = true }
      om.data.each do |order|
        order.items.each do |item|
          sheet.add_row [
            order.id,
            item.name.gsub('LEGO ', ''),
            item.type,
            item.color,
            item.boid,
            item.qty,
          ], style: styles[:hleft]
        end
        sheet.column_widths 8, 60, 11, 11, 11, 11, 3
      end
    end
  end

  def generate_sheet_orders
    workbook.add_worksheet(name: 'Orders') do |sheet|
      row = sheet.add_row %w[Id Date Status Link], style: styles[:hleft]

      0.upto(row.size - 1) { |i| row.cells[i].b = true }
      om.data.each do |order|
        sheet.add_row [
          order.id,
          order.date,
          order.status,
          order.url,
        ], style: styles[:hleft]
        sheet.column_widths 11, 11, 11, 60
      end
    end
  end


  def generate_sheet_dashboard
    package.workbook.add_worksheet(name: 'Dashboard') do |sheet|
      sheet.column_widths 30, 10, 10, 10, 10, 10

      row = sheet.add_row %w[Wishlist Items Ordered Rem. Cart Result],
        style: [
          styles[:hleft], styles[:hcenter], styles[:hcenter], styles[:hcenter], styles[:hcenter], styles[:hcenter]
        ]

      0.upto(row.size - 1) { |i| row.cells[i].b = true }
      wm.data.each_with_index do |wishlist, i|
        sheet.add_row [
          wishlist.raw_name,
          "=SUMIF(Items!$A:$A,$A#{i+2},Items!$E:$E)",
          "=SUMIF(Items!$A:$A,$A#{i+2},Items!$K:$K)",
          "=SUMIF(Items!$A:$A,$A#{i+2},Items!$M:$M)",
          "=SUMIF(Items!$A:$A,$A#{i+2},Items!$N:$N)",
          "=D#{i+2}-E#{i+2}"
        ], style: [
          styles[:hleft], styles[:hcenter], styles[:hcenter], styles[:hcenter], styles[:hcenter], styles[:hcenter]
        ]
      end

      %w[B D F].each do |column|
        sheet.add_conditional_formatting("#{column}2:#{column}#{wm.data.size+1}", type: :cellIs,
                                         operator: :equal,
                                         formula: '=0',
                                         dxfId: styles[:green],
                                         priority: 1)
        sheet.add_conditional_formatting("#{column}2:#{column}#{wm.data.size+1}", type: :cellIs,
                                         operator: :lessThan,
                                         formula: '6',
                                         dxfId: styles[:yellow],
                                         priority: 1)
      end
    end
  end
end
