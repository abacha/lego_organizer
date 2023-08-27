require 'rubygems'
require 'sinatra'
require_relative 'wishlist_manager'
require_relative 'collection_manager'
require_relative 'order_manager'
require_relative 'exporter'
require_relative 'dashboard'
RestClient.log = 'stdout'

helpers do
  def wishlist_manager
    WishlistManager.instance
  end

  def collection_manager
    CollectionManager.instance
  end

  def order_manager
    OrderManager.instance
  end

  def text_class(n)
    if n == 0
      'bg-success'
    elsif n < 6
      'bg-warning'
    end
  end
end

get '/wishlists' do
  @wishlists = wishlist_manager.data
  @title = 'Wishlists'
  erb :wishlists
end

get '/collections' do
  @collections = collection_manager.data
  @title = 'Collections'
  erb :collections
end

get '/collections/:id' do
  collection_manager.populate_items(params[:id])
  collection = collection_manager.by_id(params[:id])
  @items = collection.items
  @title = collection.name
  erb :items
end

get '/wishlists/:id' do
  wishlist_manager.populate_items(params[:id])
  wishlist = wishlist_manager.by_id(params[:id])
  @items = wishlist.items
  @title = wishlist.name
  erb :items
end

get '/wishlists/intersect/:origin/:target' do
  @items = wishlist_manager.intersect(params[:origin], params[:target])
  erb :items
end

get '/items' do
  @items = wishlist_manager.grouped_items

  erb :items
end

get '/orders' do
  @orders = order_manager.data
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
  order_manager.flush
  200
end

get '/' do
  @dashboard = Dashboard.new.generate
  erb :dashboard
end
