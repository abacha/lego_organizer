require 'rubygems'
require 'sinatra'
require_relative 'wishlist_manager'
require_relative 'exporter'
RestClient.log = 'stdout'

helpers do
  def wishlist_manager
    WishlistManager.instance
  end

  def order_manager
    OrderManager.instance
  end
end

get '/wishlists' do
  @wishlists = wishlist_manager.wishlists
  erb :wishlists
end

get '/wishlists/:id' do
  wishlist_manager.populate_items(params[:id])
  @items = wishlist_manager.wishlist(params[:id]).items
  erb :items
end

get '/items' do
  @items = wishlist_manager.grouped_items

  erb :items
end

get '/orders' do
  @orders = order_manager.orders
  erb :orders
end

get '/orders/:id' do
  order_manager.populate_items(params[:id])
  @items = order_manager.order(params[:id]).items
  erb :items
end

get '/generate_spreadsheet' do
  Exporter.new.generate_spreadsheet
  send_file './lego.xlsx', filename: 'Lego.xlsx', type: 'application/xml'
end

get '/clear_cache' do
  wishlist_manager.flush
  200
end
