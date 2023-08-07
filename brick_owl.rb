require 'rest-client'
require 'json'
require 'awesome_print'
require 'pry'
require 'dalli'


class BrickOwl
  API_KEY='b3d241b002a40564c021078b7256faab0bf1acbefa36ded0968b5824d640e3a3'

  def cache
    @cache ||= Dalli::Client.new('localhost:11211', namespace: "brickowl" , expires_in: 900)
  end

  def catalog_lookup(boids)
    get 'catalog/bulk_lookup', boids: boids
  end

  def wishlist_lots(wishlist_id)
    get 'wishlist/lots', wishlist_id: wishlist_id
  end

  def wishlists
    get 'wishlist/lists'
  end

  def orders
    get 'order/list', list_type: :customer
  end

  def order_items(order_id)
    get 'order/items', order_id: order_id
  end

  private

  def get(url, params = {})
    params.merge!(key: API_KEY)
    params_string = params.map { |key, value| "#{key}=#{value}" }.join('&')
    base_url = 'https://api.brickowl.com/v1/'
    request_url = base_url + url + "?#{params_string}"

    data = request(request_url)
    JSON.parse(data, symbolize_names: true)
  end

  def request(url)
    cache.get(url) ||
      begin
        response = RestClient.get(url).body
        puts "Cached: #{url}"
        cache.set(url, response, 300)
        response
      end
  end
end
