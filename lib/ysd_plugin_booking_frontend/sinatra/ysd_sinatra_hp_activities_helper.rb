module Sinatra
  module YitoExtension
    module BookingActivitiesFrontendRESTApiHelper

      #
      # Build the activities shopping cart
      #
      def activities_shopping_cart_to_json(shopping_cart)

        products = nil
        products_hash = {}

        # Get the shopping cart products
        products = ::Yito::Model::Booking::Activity.all(fields: [:id, :code, :name, :short_description, :description] ,
                                                        conditions: {code: (shopping_cart.shopping_cart_items.map { |item| item.item_id}).uniq} ).map do |activity|
          activity.translate(session[:locale])
        end

        # Build the products information
        domain = SystemConfiguration::Variable.get_value('site.domain')
        products.each do |product|
          full_photo = nil
          full_photo = product.photo_url_full.match(/^https?:/) ? product.photo_url_full : File.join(domain, product.photo_url_full) if product.photo_url_full
          medium_photo = nil
          medium_photo = product.photo_url_medium.match(/^https?:/) ? product.photo_url_medium : File.join(domain, product.photo_url_medium) if product.photo_url_medium
          products_hash.store(product.code, {id: product.id, code: product.code, name: product.name,
                                             short_description: product.short_description,
                                             description: product.description,
                                             full_photo: full_photo,
                                             medium_photo: medium_photo})
        end

        # Prepare the response
        p_json = products_hash.to_json
        sc_json = shopping_cart.to_json(methods: [:shopping_cart_items_group_by_date_time_item_id,
                                                  :can_make_request, :can_pay_deposit, :can_pay_total])

        "{\"shopping_cart\": #{sc_json}, \"products\": #{p_json}}"

      end

    end
  end
end