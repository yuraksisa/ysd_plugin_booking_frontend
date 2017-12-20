module Sinatra
  module YitoExtension

    module BookingActivitiesFrontendRESTApi

      def self.registered(app)

         #
         # GET /api/booking-activities/frontend/activities
         #
         # Get the activities summary
         #
         app.get '/api/booking-activities/frontend/activities' do

           activities = ::Yito::Model::Booking::Activity.all(active: true)

           status 200
           content_type :json
           activities.to_json(only: [:id, :name, :short_description, :from_price, :from_price_offer, :photo_url_medium,
                                     :photo_url_full])

         end

         #
         # GET /api/booking-activities/frontend/activities/:id
         #
         # Get an activity detail
         #
         app.get '/api/booking-activities/frontend/activities/:id' do

           activity = ::Yito::Model::Booking::Activity.get(params[:id])

           status 200
           content_type :json
           activity.to_json

         end

         #
         # GET /api/booking-activities/frontend/activities/:id/tickets
         #
         # Get the tickets that can be sold for the activity
         #
         #
         app.get '/api/booking-activities/frontend/activities/:id/tickets' do

           if activity = ::Yito::Model::Booking::Activity.get(params[:id])
             if activity.active
               tickets = nil
               if params[:activity_date_id] # Multiple dates activity

               elsif params[:date] and params[:turn] # Cyclic activity
                 tickets = activity.tickets(Date.strptime(params[:date],'%d/%m/%Y'), params[:turn])
               end
               
               status 200
               content_type :json
               tickets.to_json
             else
               status 422
             end
           else
             status 404
           end

         end

         # ------------------------ Shopping cart management -----------------------------------------------

         #
         # GET /api/booking-activities/frontend/shopping-cart
         #
         # Get the shopping cart
         #
         app.route :get, ['/api/booking-activities/frontend/shopping-cart',
                          '/api/booking-activities/frontend/shopping-cart/:free_access_id'] do

           shopping_cart = products = nil
           products_hash = {}

           # Get the shopping cart
           if params[:free_access_id]
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get_by_free_access_id(params[:free_access_id])
           elsif session.has_key?(:shopping_cart_id)
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
           end

           # Build the products hash with full information about the products in the shopping cart
           unless shopping_cart.nil?
             products = ::Yito::Model::Booking::Activity.all(fields: [:id, :code, :name, :short_description, :description] ,
                                                             conditions: {code: (shopping_cart.shopping_cart_items.map { |item| item.item_id}).uniq} )
             domain = SystemConfiguration::Variable.get_value('site.domain')
             products.each do |product|
               products_hash.store(product.code, {id: product.id, code: product.code, name: product.name,
                                                  short_description: product.short_description,
                                                  description: product.description,
                                                  full_photo: product.photo_url_full.match(/^https?:/) ? product.photo_url_full : File.join(domain, product.photo_url_full),
                                                  medium_photo: product.photo_url_medium.match(/^https?:/) ? product.photo_url_medium : File.join(domain, product.photo_url_medium)})
             end
           end
           
           # Prepare the response
           p_json = products_hash.to_json
           sc_json = shopping_cart.to_json(methods: [:shopping_cart_items_group_by_date_time_item_id, 
                                                     :can_make_request, :can_pay_deposit, :can_pay_total])

           status 200
           content_type :json
           "{\"shopping_cart\": #{sc_json}, \"products\": #{p_json}}"

         end

         #
         # POST /api/booking-activities/frontend/add-to-shopping-cart
         #
         # Add an activity to the shopping cart
         #
         app.route :post, ['/api/booking-activities/frontend/add-to-shopping-cart',
                           '/api/booking-activities/frontend/add-to-shopping-cart/:free_access_id'] do

           # Extract the data parameters
           begin
             request.body.rewind
             model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
           rescue JSON::ParserError
             halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
           end
           
           # Retrieve the shopping cart
           if params[:free_access_id]
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get_by_free_access_id(params[:free_access_id])
           elsif session.has_key?(:shopping_cart_id)
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
           end

           # Request parameters
           activity_id = model_request[:id]
           tickets = model_request[:tickets]
           custom_customers_pickup_place = model_request[:custom_customers_pickup_place].to_bool if params.has_key?('custom_customers_pickup_place')
           customers_pickup_place = model_request[:customers_pickup_place] if params.has_key?('customers_pickup_place')

           # Activity
           if activity = ::Yito::Model::Booking::Activity.get(activity_id)

             ::Yito::Model::Order::ShoppingCart.transaction do
               activity_name = activity.name
               activity_options = {
                   request_customer_information: activity.request_customer_information,
                   request_customer_address: activity.request_customer_address,
                   request_customer_document_id: activity.request_customer_document_id,
                   request_customer_phone: activity.request_customer_phone,
                   request_customer_email: activity.request_customer_email,
                   request_customer_height: activity.request_customer_height,
                   request_customer_weight: activity.request_customer_weight,
                   request_customer_allergies_intolerances: activity.request_customer_allergies_intolerances,
                   uses_planning_resources: activity.uses_planning_resources
               }
               # Create the shopping cart if not exist
               if shopping_cart.nil?
                 shopping_cart = ::Yito::Model::Order::ShoppingCart.create(:creation_date => DateTime.now,
                                                                           customer_language: session[:locale])
                 session[:shopping_cart_id] = shopping_cart.id
               end

               if activity.occurence == :cyclic
                 date= model_request[:date]
                 time= model_request[:turn]
               end

               # Appends the items (three kind of rates)
               if !tickets.nil? and tickets.has_key?(:"1") and tickets[:"1"] > 0
                  shopping_cart.add_item(date,
                                         time,
                                         activity.code,
                                         activity_name,
                                         1,
                                         tickets[:"1"],
                                         activity.rates(date)[1][1],
                                         activity.price_1_description,
                                         custom_customers_pickup_place,
                                         customers_pickup_place,
                                         activity.price_1_affects_capacity ? activity_options : {})
               end

               if !tickets.nil? and tickets.has_key?(:"2") and tickets[:"2"] > 0
                  shopping_cart.add_item(date,
                                         time,
                                         activity.code,
                                         activity_name,
                                         2,
                                         tickets[:"2"],
                                         activity.rates(date)[2][1],
                                         activity.price_2_description,
                                         custom_customers_pickup_place,
                                         customers_pickup_place,
                                         activity.price_2_affects_capacity ? activity_options : {})
               end

               if !tickets.nil? and tickets.has_key?(:"3") and tickets[:"3"] > 0
                  shopping_cart.add_item(date,
                                         time,
                                         activity.code,
                                         activity_name,
                                         3,
                                         tickets[:"3"],
                                         activity.rates(date)[3][1],
                                         activity.price_3_description,
                                         custom_customers_pickup_place,
                                         customers_pickup_place,
                                         activity.price_3_affects_capacity ? activity_options : {})
               end

               status 200
               content_type :json
               shopping_cart.id.to_json

             end

           else
             halt 422, {error: 'Invalid request. Activity not found'}
           end
             
           

         end

         #
         # POST /api/booking-activities/frontend/remove-from-shopping-cart
         #
         # Remove an activity from the shopping cart
         #
         app.route :post, ['/api/booking-activities/frontend/remove-from-shopping-cart',
                           '/api/booking-activities/frontend/remove-from-shopping-cart/:free_access_id'] do

         end

         #
         # POST /api/booking-activities/frontend/create-order
         #
         # Checkout the shopping cart => Creates an order from the shopping cart
         #
         app.route :post, ['/api/booking-activities/frontend/create-order',
                           '/api/booking-activities/frontend/create-order/:free_access_id'] do

           # Extract the data parameters
           begin
             request.body.rewind
             model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
           rescue JSON::ParserError
             halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
           end

           p "model_request: #{model_request.inspect}"

           # Retrieve the shopping cart
           if params[:free_access_id]
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get_by_free_access_id(params[:free_access_id])
           elsif session.has_key?(:shopping_cart_id)
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
           end

           if shopping_cart
             shopping_cart.transaction do
               begin
                 # Update customers detail
                 if model_request.has_key?(:shopping_cart_item_customers)
                   model_request[:shopping_cart_item_customers].each do |item|
                     if shopping_cart_item_customer = ::Yito::Model::Order::ShoppingCartItemCustomer.get(item[:id])
                       shopping_cart_item_customer.customer_name = item[:customer_name] if item.has_key?('customer_name')
                       shopping_cart_item_customer.customer_surname = item[:customer_surname] if item.has_key?('customer_surname')
                       shopping_cart_item_customer.customer_document_id = item[:customer_document_id] if item.has_key?('customer_document_id')
                       shopping_cart_item_customer.customer_phone = item[:customer_phone] if item.has_key?('customer_phone')
                       shopping_cart_item_customer.customer_email = item[:customer_email] if item.has_key?('customer_email')
                       shopping_cart_item_customer.customer_height = item[:customer_height] if item.has_key?('customer_height')
                       shopping_cart_item_customer.customer_weight = item[:customer_weight] if item.has_key?('customer_weight')
                       shopping_cart_item_customer.customer_allergies_or_intolerances = item[:customer_allergies_or_intolerances] if item.has_key?('customer_allergies_or_intolerances')
                       shopping_cart_item_customer.save
                     end
                   end
                   shopping_cart.reload
                 end
                 order = ::Yito::Model::Order::Order.create_from_shopping_cart(shopping_cart)
                 order.comments = model_request[:comments]
                 order.customer_name = model_request[:customer_name]
                 order.customer_surname = model_request[:customer_surname]
                 order.customer_email = model_request[:customer_email]
                 order.customer_phone = model_request[:customer_phone]
                 order.customer_language = session[:locale] || 'es'
                 order.init_user_agent_data(request.env["HTTP_USER_AGENT"])
                 allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
                 deposit = SystemConfiguration::Variable.get_value('order.deposit').to_i
                 if allow_deposit_payment and deposit > 0
                   order.reservation_amount = (order.total_cost * deposit / 100).round
                 end
                 # Update order address
                 if order.request_customer_address
                   customer_address = LocationDataSystem::Address.new
                   customer_address.street = model_request[:street] if model_request.has_key?(:street)
                   customer_address.number = model_request[:number]  if model_request.has_key?(:number)
                   customer_address.complement = model_request[:complement] if model_request.has_key?(:complement)
                   customer_address.city = model_request[:city] if model_request.has_key?(:city)
                   customer_address.state = model_request[:state] if model_request.has_key?(:state)
                   customer_address.country = model_request[:country] if model_request.has_key?(:country)
                   customer_address.zip = model_request[:zip] if model_request.has_key?(:zip)
                   customer_address.save
                   order.customer_address = customer_address
                 end
                 order.save
                 shopping_cart.destroy

                 status 200
                 content_type :json
                 order.free_access_id.to_json

               rescue DataMapper::SaveFailureError => error
                 p "Error creating order from shopping cart. #{order.inspect} #{order.errors.inspect}"
                 raise error
               end

             end

           else

             halt 422, {error: 'Shopping cart does not exist'}

           end


         end


         # ------------------------ Order management -----------------------------------------------

         #
         # GET /api/booking-activities/frontend/orders/:free_access_id
         #
         # Get an order
         #
         app.get '/api/booking-activities/frontend/shopping-cart/:free_access_id' do
           
         end

      end

    end
  end
end