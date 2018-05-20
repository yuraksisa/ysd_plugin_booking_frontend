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

           activities = ::Yito::Model::Booking::Activity.all(active: true, web_public: true).map do |activity|
                          t_activity = activity.translate(session[:locale])
                          t_activity.alias = format_url_with_language(t_activity.alias)
                          t_activity
                        end
           status 200
           content_type :json
           activities.to_json(only: [:id, :name, :short_description, :from_price, :from_price_offer, :photo_url_medium,
                                     :photo_url_full, :alias])

         end

         #
         # GET /api/booking-activities/frontend/activities/:id
         #
         # Get an activity detail
         #
         app.get '/api/booking-activities/frontend/activities/:id' do

           if activity = ::Yito::Model::Booking::Activity.get(params[:id])
             t_activity = activity.translate(session[:locale])
             t_activity.alias = format_url_with_language(activity.alias)
             status 200
             content_type :json
             t_activity.to_json
           else
             status 404
           end

         end

         #
         # GET /api/booking-activities/frontend/activities/:id/dates
         #
         # Get the activity dates
         #
         app.get '/api/booking-activities/frontend/activities/:id/dates' do

           if activity = ::Yito::Model::Booking::Activity.get(params[:id]) and
              activity.occurence == :multiple_dates
             # TODO Take into account real occupation
             activity_dates = ::Yito::Model::Booking::ActivityDate.all(conditions: {:activity_id => activity.id,
                                                                                    :date_from.gte => Date.today},
                                                                       order: [:date_from.asc])
             status 200
             content_type :json
             activity_dates.to_json({only: [:id, :description]})
           else
             status 404
           end

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
                 if activity_date = ::Yito::Model::Booking::ActivityDate.get(params[:activity_date_id])
                   tickets = activity.translate(session[:locale]).tickets(activity_date.date_from, activity_date.time_from)
                 end
               elsif params[:date] and params[:turn] # Cyclic activity
                 tickets = activity.translate(session[:locale]).tickets(parse_date(params[:date], session[:locale]), params[:turn])
               else # One time activity
                 tickets = activity.translate(session[:locale]).tickets(activity.date_from, activity.time_from)
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

           shopping_cart = nil

           # Get the shopping cart
           if params[:free_access_id]
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get_by_free_access_id(params[:free_access_id])
           elsif session.has_key?(:shopping_cart_id)
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
           end

           if shopping_cart.nil?
             halt 404, 'Shopping cart not found'
           end

           status 200
           content_type :json
           activities_shopping_cart_to_json(shopping_cart)

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
                   uses_planning_resources: activity.uses_planning_resources,
                   own_contract: activity.own_contract,
                   custom_payment_allow_deposit_payment: activity.custom_payment_allow_deposit_payment,
                   custom_payment_deposit: activity.custom_payment_deposit,
                   custom_payment_allow_total_payment: activity.custom_payment_allow_total_payment,
                   allow_request_reservation: activity.allow_request_reservation
               }
               # Create the shopping cart if not exist
               if shopping_cart.nil?
                 shopping_cart = ::Yito::Model::Order::ShoppingCart.create(:creation_date => DateTime.now,
                                                                           customer_language: session[:locale])
                 session[:shopping_cart_id] = shopping_cart.id
               end

               if activity.occurence == :cyclic
                 date= parse_date(model_request[:date], session[:locale])
                 time= model_request[:turn]
               elsif activity.occurence == :multiple_dates
                 if activity_date = ::Yito::Model::Booking::ActivityDate.get(model_request[:activity_date_id])
                   date = activity_date.date_from
                   time = activity_date.time_from
                 else
                   halt 422, {error: 'date is not setup for the activity'}.to_json
                 end
               elsif activity.occurence == :one_time
                 date = activity.date_from
                 time = activity.time_from
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
                                         activity_options)
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
                                         activity_options)
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
                                         activity_options)
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
           date = model_request[:date]
           time = model_request[:time]
           item_id = model_request[:item_id]

           if !model_request.has_key?(:date) or !model_request.has_key?(:time) or !model_request.has_key?(:item_id)
             halt 422, {error: 'Invalid request parameters'}.to_json
           end

           # Retrieve the shopping cart
           if params[:free_access_id]
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get_by_free_access_id(params[:free_access_id])
           elsif session.has_key?(:shopping_cart_id)
             shopping_cart = ::Yito::Model::Order::ShoppingCart.get(session[:shopping_cart_id])
           end

           if shopping_cart.nil?
             halt 404, {error: 'Shopping cart not found'}.to_json
           end

           begin
              shopping_cart.transaction do
                shopping_cart.remove_item(date, time, item_id)
                status 200
                content_type :json
                activities_shopping_cart_to_json(shopping_cart)
              end
           rescue DataMapper::SaveFailureError => error
             p "Error removing item from shopping cart. #{error.inspect} #{error.resource.full_messages.inspect}"
             raise error
           end


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
                 if order.can_pay_deposit?
                   deposit = SystemConfiguration::Variable.get_value('order.deposit').to_i
                   if deposit > 0
                     order.reservation_amount = (order.total_cost * deposit / 100).round
                   end
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

                 begin
                   if model_request.has_key?(:payment)
                     order.send_new_order_notifications(model_request[:payment] != 'none')
                   end
                 rescue
                   p "Error sending notifications. Order: #{order.id}"
                 end

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
         app.get '/api/booking-activities/frontend/order/:free_access_id' do

         end

         #
         # Updates an order
         #
         app.put '/api/booking-activities/frontend/order/:free_access_id' do

           # Extract the data parameters
           begin
             request.body.rewind
             model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
           rescue JSON::ParserError
             halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
           end

           if @order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:free_access_id])
             @order.transaction do
               begin
                 if model_request.has_key?(:customer_address)
                   @order.customer_address = LocationDataSystem::Address.new if @order.customer_address.nil?
                   @order.customer_address.street = model_request[:customer_address][:street] if model_request[:customer_address].has_key?(:street)
                   @order.customer_address.number = model_request[:customer_address][:number] if model_request[:customer_address].has_key?(:number)
                   @order.customer_address.complement = model_request[:customer_address][:complement] if model_request[:customer_address].has_key?(:complement)
                   @order.customer_address.city = model_request[:customer_address][:city] if model_request[:customer_address].has_key?(:city)
                   @order.customer_address.state = model_request[:customer_address][:state] if model_request[:customer_address].has_key?(:state)
                   @order.customer_address.country = model_request[:customer_address][:country] if model_request[:customer_address].has_key?(:country)
                   @order.customer_address.zip = model_request[:customer_address][:zip] if model_request[:customer_address].has_key?(:zip)
                   @order.customer_address.save
                   @order.save
                 end
                 if model_request.has_key?(:order_item_customers)
                   model_request[:order_item_customers].each do |item|
                     if order_item_customer = ::Yito::Model::Order::OrderItemCustomer.get(item[:id])
                       order_item_customer.customer_name = item[:customer_name] if item.has_key?(:customer_name)
                       order_item_customer.customer_surname = item[:customer_surname] if item.has_key?(:customer_surname)
                       order_item_customer.customer_document_id = item[:customer_document_id] if item.has_key?(:customer_document_id)
                       order_item_customer.customer_phone = item[:customer_phone] if item.has_key?(:customer_phone)
                       order_item_customer.customer_email = item[:customer_email] if item.has_key?(:customer_email)
                       order_item_customer.customer_height = item[:customer_height] if item.has_key?(:customer_height)
                       order_item_customer.customer_weight = item[:customer_weight] if item.has_key?(:customer_weight)
                       order_item_customer.customer_allergies_or_intolerances = item[:customer_allergies_or_intolerances] if item.has_key?(:customer_allergies_or_intolerances)
                       order_item_customer.save
                     end
                   end
                 end
                 status 200
                 content_type :json
                 true.to_json
               rescue DataMapper::SaveFailureError => error
                 p "Error updating order. #{@order.inspect} #{@order.errors.full_messages.inspect}"
                 raise error
               end
             end
           else
             halt 404
           end

         end

      end

    end
  end
end