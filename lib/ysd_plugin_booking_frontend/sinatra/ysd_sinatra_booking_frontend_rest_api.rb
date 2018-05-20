module Sinatra
  module YitoExtension

    module BookingFrontendRESTApi

      def self.registered(app)

        #
        # Get information from the server
        #
        app.get '/api/booking/frontend/settings' do

          server_timestamp = DateTime.now

          domain = SystemConfiguration::Variable.get_value('site.domain')
          products = ::Yito::Model::Booking::BookingCategory.all(
                       fields: [:code, :name, :short_description, :description, :from_price, :from_price_offer],
                       conditions: {active: true, web_public: true},
                       order: [:code]).map do |item|

                          photo = item.album ? item.album.thumbnail_medium_url : nil
                          full_photo = item.album ? item.album.image_url : nil
                          photo_path = nil
                          if photo
                            photo_path = (photo.match(/^https?:/) ? photo : File.join(domain, photo))
                          end
                          full_photo_path = nil
                          if full_photo
                            full_photo_path = (full_photo.match(/^https?:/) ? full_photo : File.join(domain, full_photo))
                          end

                          {code: item.code, name: item.name,
                           short_description: item.short_description, description: item.description,
                           from_price: item.from_price, from_price_offer: item.from_price_offer,
                           photo_path: photo_path, full_photo_path: full_photo_path}
                      end

          settings = {server_date: server_timestamp.strftime('%Y-%m-%d'),
                      server_time: server_timestamp.strftime('%H:%M'),
                      products: products}

          content_type 'json'
          settings.to_json
        end

        #
        # Get the pickup places
        #
        app.get '/api/booking/frontend/pickup-places' do

          places = BookingDataSystem.pickup_places.map do |item|
            item_translation = item.translate(session[:locale])
            {id: item.name, name: item_translation.name, price: item.price}
          end

          content_type 'json'
          places.to_json

        end

        #
        # Get the return places
        #
        app.get '/api/booking/frontend/return-places' do

          places = BookingDataSystem.return_places.map do |item|
            item_translation = item.translate(session[:locale])
            {id: item.name, name: item_translation.name, price: item.price}
          end

          content_type 'json'
          places.to_json

        end

        #
        # Get the pickup /return time
        #
        app.get '/api/booking/frontend/pickup-return-times' do

          content_type 'json'
          BookingDataSystem.pickup_return_timetable.to_json

        end

        # ------------------------------- Product ---------------------------------------------------

        #
        # Set/add the product
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-product',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-product'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          product_code = model_request[:product]
          quantity = model_request.has_key?(:quantity) ? model_request[:quantity].to_i : 1

          # TODO : Validate it's a valid product

          # Retrieve the shopping cart
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Do the process
          if shopping_cart
            booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            shopping_cart.set_item(product_code, quantity, booking_item_family.multiple_items?)
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        # ------------------------------- Extras ---------------------------------------------------

        #
        # Set an extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/set-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/set-extra'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          extra_code = model_request[:extra]
          extra_quantity = model_request[:quantity].to_i || 1

          # TODO : Validate it's a valid extra

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            if extra_quantity > 0
              shopping_cart.set_extra(extra_code, extra_quantity)
            else
              shopping_cart.remove_extra(extra_code)
            end
            #setup_session_locale_from_params
            content_type :json
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Remove extra
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/remove-extra',
                          '/api/booking/frontend/shopping-cart/:free_access_id/remove-extra'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end
          extra_code = model_request[:extra]

          # TODO : Validate it's a valid extra and it's contained in the shopping cart

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            shopping_cart.remove_extra(extra_code)
            #setup_session_locale_from_params
            content_type :json
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            halt 404, {error: 'Shopping cart not found'}.to_json
          end

        end

        # ------------------------------- Checkout (confirm) ----------------------------------------------

        #
        # Confirm reservation
        #
        app.route :post, ['/api/booking/frontend/shopping-cart/checkout',
                          '/api/booking/frontend/shopping-cart/:free_access_id/checkout'] do

          # Request data
          request.body.rewind
          request_data = JSON.parse(URI.unescape(request.body.read))

          # Retrieve the shopping cart
          shopping_cart = if params[:free_access_id]
                            ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
                          elsif session.has_key?(:shopping_cart_renting_id)
                            ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
                          end

          # Do the process
          if shopping_cart
            # Basic data: customer, payment and comments
            shopping_cart.customer_name = request_data['customer_name'] || request_data['driver_name']
            shopping_cart.customer_surname = request_data['customer_surname'] || request_data['driver_surname']
            shopping_cart.customer_email = request_data['customer_email']
            shopping_cart.customer_phone = request_data['customer_phone']
            shopping_cart.customer_mobile_phone = request_data['customer_mobile_phone']
            shopping_cart.customer_document_id = request_data['customer_document_id'] || request_data['driver_document_id']
            shopping_cart.customer_language = request_data['customer_language'] if request_data.has_key?('customer_language')
            shopping_cart.comments = request_data['comments']
            shopping_cart.destination_accommodation = request_data['destination_accommodation'] if request_data.has_key?('destination_accommodation')
            shopping_cart.pay_now =  (request_data['payment'] != 'none')
            shopping_cart.payment_method_id = (request_data['payment'] != 'none' ? request_data['payment'] : nil)
            # Number of adults/children (accomodation)
            shopping_cart.number_of_adults = request_data['number_of_adults'] if request_data.has_key?('number_of_adults')
            shopping_cart.number_of_children = request_data['number_of_children'] if request_data.has_key?('number_of_children')
            # Driver data (car/bike/truck renting)
            shopping_cart.driver_name = request_data['driver_name'] if request_data.has_key?('driver_name')
            shopping_cart.driver_surname = request_data['driver_surname']  if request_data.has_key?('driver_surname')
            shopping_cart.driver_document_id = request_data['driver_document_id'] if request_data.has_key?('driver_document_id')
            shopping_cart.driver_date_of_birth = parse_date(request_data['driver_date_of_birth'], shopping_cart.customer_language)  if request_data.has_key?('driver_date_of_birth') and !request_data['driver_date_of_birth'].nil? and !request_data['driver_date_of_birth'].to_s.empty?
            shopping_cart.driver_driving_license_number = request_data['driver_driving_license_number'] if request_data.has_key?('driver_driving_license_number')
            shopping_cart.driver_driving_license_date = parse_date(request_data['driver_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_date') and !request_data['driver_driving_license_date'].nil? and !request_data['driver_driving_license_date'].to_s.empty?
            shopping_cart.driver_driving_license_country = request_data['driver_driving_license_country'] if request_data.has_key?('driver_driving_license_country')
            shopping_cart.driver_driving_license_expiration_date = parse_date(request_data['driver_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_expiration_date') and !request_data['driver_driving_license_expiration_date'].nil? and !request_data['driver_driving_license_expiration_date'].to_s.empty?

            booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            if booking_item_family and booking_item_family.driver_date_of_birth
              shopping_cart.driver_age = BookingDataSystem::Booking.completed_years(shopping_cart.date_from,
                                                                                    shopping_cart.driver_date_of_birth) unless shopping_cart.driver_date_of_birth.nil?
            end
            if booking_item_family and booking_item_family.driver_license
              shopping_cart.driver_driving_license_years = BookingDataSystem::Booking.completed_years(shopping_cart.date_from,
                                                                                                      shopping_cart.driver_driving_license_date) unless shopping_cart.driver_driving_license_date.nil?
            end

            shopping_cart.calculate_cost(true, true) # Calculate cost using driver real date of birth and driving license date

            if shopping_cart.driver_address.nil?
              shopping_cart.driver_address = LocationDataSystem::Address.new
            end
            shopping_cart.driver_address.street = request_data['street'] if request_data.has_key?('street')
            shopping_cart.driver_address.number = request_data['number']  if request_data.has_key?('number')
            shopping_cart.driver_address.complement = request_data['complement']  if request_data.has_key?('complement')
            shopping_cart.driver_address.city = request_data['city']  if request_data.has_key?('city')
            shopping_cart.driver_address.state = request_data['state']  if request_data.has_key?('state')
            shopping_cart.driver_address.country = request_data['country']  if request_data.has_key?('country')
            shopping_cart.driver_address.zip = request_data['zip']  if request_data.has_key?('zip')
            # Additional driver
            shopping_cart.additional_driver_1_name = request_data['additional_driver_1_name'] if request_data.has_key?('additional_driver_1_name')
            shopping_cart.additional_driver_1_surname = request_data['additional_driver_1_surname'] if request_data.has_key?('additional_driver_1_surname')
            shopping_cart.additional_driver_1_document_id = request_data['additional_driver_1_document_id'] if request_data.has_key?('additional_driver_1_document_id')
            shopping_cart.additional_driver_1_document_id_date = parse_date(request_data['additional_driver_1_document_id_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_document_id_date') and !request_data['additional_driver_1_document_id_date'].nil? and !request_data['additional_driver_1_document_id_date'].to_s.empty?
            shopping_cart.additional_driver_1_document_id_expiration_date = parse_date(request_data['additional_driver_1_document_id_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_document_id_expiration_date') and !request_data['additional_driver_1_document_id_expiration_date'].nil? and !request_data['additional_driver_1_document_id_expiration_date'].to_s.empty?
            shopping_cart.additional_driver_1_origin_country = request_data['additional_driver_1_origin_country'] if request_data.has_key?('additional_driver_1_origin_country')
            shopping_cart.additional_driver_1_date_of_birth = parse_date(request_data['additional_driver_1_date_of_birth'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_date_of_birth') and !request_data['additional_driver_1_date_of_birth'].nil? and !request_data['additional_driver_1_date_of_birth'].to_s.empty?
            shopping_cart.additional_driver_1_age = age(Date.today, shopping_cart.additional_driver_1_date_of_birth) if !shopping_cart.additional_driver_1_date_of_birth.nil?
            shopping_cart.additional_driver_1_driving_license_number = request_data['additional_driver_1_driving_license_number'] if request_data.has_key?('additional_driver_1_driving_license_number')
            shopping_cart.additional_driver_1_driving_license_date = parse_date(request_data['additional_driver_1_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_driving_license_date') and !request_data['additional_driver_1_driving_license_date'].nil? and !request_data['additional_driver_1_driving_license_date'].to_s.empty?
            shopping_cart.additional_driver_1_driving_license_country = request_data['additional_driver_1_driving_license_country'] if request_data.has_key?('additional_driver_1_driving_license_country')
            shopping_cart.additional_driver_1_driving_license_expiration_date = parse_date(request_data['additional_driver_1_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_driving_license_expiration_date') and !request_data['additional_driver_1_driving_license_expiration_date'].nil? and !request_data['additional_driver_1_driving_license_expiration_date'].to_s.empty?
            shopping_cart.additional_driver_1_phone = request_data['additional_driver_1_phone'] if request_data.has_key?('additional_driver_1_phone')
            shopping_cart.additional_driver_1_email = request_data['additional_driver_1_email'] if request_data.has_key?('additional_driver_1_email')
            # Flight
            shopping_cart.flight_airport_origin = request_data['flight_airport_origin'] if request_data.has_key?('flight_airport_origin')
            shopping_cart.flight_company = request_data['flight_company'] if request_data.has_key?('flight_company')
            shopping_cart.flight_number = request_data['flight_number'] if request_data.has_key?('flight_number')
            shopping_cart.flight_time = request_data['flight_time'] if request_data.has_key?('flight_time')
            shopping_cart.flight_airport_destination = request_data['flight_airport_destination'] if request_data.has_key?('flight_airport_destination')
            shopping_cart.flight_company_departure = request_data['flight_company_departure'] if request_data.has_key?('flight_company_departure')
            shopping_cart.flight_number_departure = request_data['flight_number_departure'] if request_data.has_key?('flight_number_departure')
            shopping_cart.flight_time_departure = request_data['flight_time_departure'] if request_data.has_key?('flight_time_departure')
            begin
              shopping_cart.save
            rescue DataMapper::SaveFailureError => error
              unless shopping_cart.valid?
                logger.error "Error saving shopping cart : #{shopping_cart.errors.inspect} -- #{shopping_cart.errors.full_messages.inspect}"
                halt 422, {error: shopping_cart.errors.full_messages}.to_json
              end
              if shopping_cart.driver_address and !shopping_cart.driver_address.valid?
                logger.error "Error saving shopping cart - driver address : #{shopping_cart.driver_address.errors.inspect} -- #{shopping_cart.driver_address.errors.full_messages.inspect}"
                halt 422, {error: shopping_cart.driver_address.errors.full_messages}.to_json
              end
              logger.error "Error during checkout process. Details: #{error.resource.inspect} #{error.resource.errors.full_messages.inspect}"
              halt 422, {error: error.resource.errors.full_messages}.to_json
            end

            logger.debug "Updated shopping cart"

            # Creates the booking
            booking = nil
            begin
              booking = BookingDataSystem::Booking.create_from_shopping_cart(shopping_cart,
                                                                             request.env["HTTP_USER_AGENT"],
                                                                             false)
              shopping_cart.destroy # Destroy the converted shopping cart
            rescue DataMapper::SaveFailureError => error
              logger.error "Error creating booking from shopping cart #{error.inspect}"
              logger.error "Error details: #{error.resource.errors.full_messages.inspect}"
              halt 422, {error: error.resource.errors.full_messages}.to_json
            end

            logger.debug "Created booking"
            # Remove the shopping_cart_renting_id from the session
            session.delete(:shopping_cart_renting_id)
            # Add the booking_id to the session
            session[:booking_id] = booking.id
            # Prepare response
            content_type :json
            booking.to_json(only: [:free_access_id, :pay_now, :payment, :payment_method_id, :total_cost, :customer_email, :customer_name, :customer_surname])
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        # -------------------- Shopping cart -----------------------------------------

        #
        # Get the renting shopping cart
        #
        app.route :get, ['/api/booking/frontend/shopping-cart',
                         '/api/booking/frontend/shopping-cart/:free_access_id'] do

          shopping_cart = nil

          # Retrieve the shopping cart
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Return the shopping cart
          if shopping_cart
            if shopping_cart.customer_language != session[:locale]
              shopping_cart.change_customer_language(session[:locale])
            end
            #setup_session_locale_from_params
            content_type 'json'
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        #
        # Create/Update the renting shopping cart
        #
        app.route :post, ['/api/booking/frontend/shopping-cart',
                          '/api/booking/frontend/shopping-cart/:free_access_id'] do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            content_type :json
            status 422
            {error: 'Invalid request. Expected a JSON with data params'}.to_json
            halt
          end

          # TODO Check parameters
          date_from = time_from = date_to = time_to = pickup_place = return_place = number_of_adults = number_of_children =
              driver_age_rule_id = sales_channel_code = promotion_code = nil

          if model_request[:date_from] && model_request[:date_to]
            # Retrieve date/time from - to
            date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
            time_from = model_request[:time_from]
            date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
            time_to = model_request[:time_to]
            # Retrieve pickup/return place
            pickup_place, custom_pickup_place, pickup_place_customer_translation,
            return_place, custom_return_place, return_place_customer_translation = request_pickup_return_place(model_request)
            # Retrieve number of adutls and children
            number_of_adults = model_request[:number_of_adults] if model_request.has_key?(:number_of_adults)
            number_of_children = model_request[:number_of_children] if model_request.has_key?(:number_of_childen)
            # Retrieve driver age rule
            driver_age_rule_id = model_request[:driver_age_rule] if model_request.has_key?(:driver_age_rule)
            # Retrieve sales channel
            sales_channel_code = model_request[:sales_channel_code] if model_request.has_key?(:sales_channel_code)
            sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?
            # Retrieve promotion code
            promotion_code = model_request[:promotion_code] if model_request.has_key?(:promotion_code)
            promotion_code = nil if promotion_code and promotion_code.empty?
          else
            content_type :json
            status 422
            {error: 'Invalid request. data_from and date_to are required.'}.to_json
            halt
          end

          # Retrieve the shopping cart
          shopping_cart = nil
          if params[:free_access_id]
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get_by_free_access_id(params[:free_access_id])
          elsif session.has_key?(:shopping_cart_renting_id)
            shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
          end

          # Updates or creates the shopping cart with the new dates or do create a new one if it does not exist
          if shopping_cart
            shopping_cart.change_selection_data(date_from, time_from,
                                                date_to, time_to,
                                                pickup_place, custom_pickup_place,
                                                return_place, custom_return_place,
                                                number_of_adults, number_of_children,
                                                driver_age_rule_id, sales_channel_code, promotion_code)
            if shopping_cart.customer_language != session[:locale]
              shopping_cart.change_customer_language(session[:locale])
            end
          else
            shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.create(
                date_from: date_from, time_from: time_from,
                date_to: date_to, time_to: time_to,
                pickup_place: pickup_place,
                pickup_place_customer_translation: pickup_place_customer_translation,
                custom_pickup_place: custom_pickup_place,
                return_place: return_place,
                return_place_customer_translation: return_place_customer_translation,
                custom_return_place: custom_return_place,
                number_of_adults: number_of_adults,
                number_of_children: number_of_children,
                driver_age_rule_id: driver_age_rule_id,
                sales_channel_code: sales_channel_code,
                promotion_code: promotion_code,
                customer_language: session[:locale])
            session[:shopping_cart_renting_id] = shopping_cart.id
          end

          # Return the shopping cart
          if shopping_cart
            #setup_session_locale_from_params
            content_type 'json'
            status 200
            shopping_cart_to_json(shopping_cart)
          else
            logger.error "No shopping cart"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

        # ----------------------------- Reservation -----------------------------------------

        #
        # Get the reservation
        #
        app.get '/api/booking/frontend/booking/:free_access_id' do

          booking = BookingDataSystem::Booking.get_by_free_access_id(params[:free_access_id])

          if booking
            content_type 'json'
            booking_to_json(booking)
          else
            logger.error "Booking not found #{params[:id]}"
            content_type 'json'
            status 404
            {error: 'Booking not found'}.to_json
          end

        end

        #
        # Update the reservation
        #
        app.put '/api/booking/frontend/booking/:free_access_id' do

          # Extract the data parameters
          begin
            request.body.rewind
            model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
          rescue JSON::ParserError
            halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
          end

          if @booking = BookingDataSystem::Booking.get_by_free_access_id(params[:free_access_id])
            @booking.transaction do
              begin
                if model_request.has_key?(:customer_address)
                  @booking.driver_address = LocationDataSystem::Address.new if @booking.driver_address.nil?
                  @booking.driver_address.street = model_request[:customer_address][:street] if model_request[:customer_address].has_key?(:street)
                  @booking.driver_address.number = model_request[:customer_address][:number] if model_request[:customer_address].has_key?(:number)
                  @booking.driver_address.complement = model_request[:customer_address][:complement] if model_request[:customer_address].has_key?(:complement)
                  @booking.driver_address.city = model_request[:customer_address][:city] if model_request[:customer_address].has_key?(:city)
                  @booking.driver_address.state = model_request[:customer_address][:state] if model_request[:customer_address].has_key?(:state)
                  @booking.driver_address.country = model_request[:customer_address][:country] if model_request[:customer_address].has_key?(:country)
                  @booking.driver_address.zip = model_request[:customer_address][:zip] if model_request[:customer_address].has_key?(:zip)
                  @booking.driver_address.save
                  @booking.save
                end
                if model_request.has_key?(:booking_line_resources)
                  model_request[:booking_line_resources].each do |item|
                    if booking_line_resource = BookingDataSystem::BookingLineResource.get(item[:id])
                      booking_line_resource.resource_user_name = item[:resource_user_name] if item.has_key?(:resource_user_name)
                      booking_line_resource.resource_user_surname = item[:resource_user_surname] if item.has_key?(:resource_user_surname)
                      booking_line_resource.resource_user_document_id = item[:resource_user_document_id] if item.has_key?(:resource_user_document_id)
                      booking_line_resource.resource_user_phone = item[:resource_user_phone] if item.has_key?(:resource_user_phone)
                      booking_line_resource.resource_user_email = item[:resource_user_email] if item.has_key?(:resource_user_email)
                      booking_line_resource.customer_height = item[:customer_height] if item.has_key?(:customer_height)
                      booking_line_resource.customer_weight = item[:customer_weight] if item.has_key?(:customer_weight)
                      booking_line_resource.resource_user_2_name = item[:resource_user_2_name] if item.has_key?(:resource_user_2_name)
                      booking_line_resource.resource_user_2_surname = item[:resource_user_2_surname] if item.has_key?(:resource_user_2_surname)
                      booking_line_resource.resource_user_2_document_id = item[:resource_user_2_document_id] if item.has_key?(:resource_user_2_document_id)
                      booking_line_resource.resource_user_2_phone = item[:resource_user_2_phone] if item.has_key?(:resource_user_2_phone)
                      booking_line_resource.resource_user_2_email = item[:resource_user_2_email] if item.has_key?(:resource_user_2_email)
                      booking_line_resource.customer_2_height = item[:customer_2_height] if item.has_key?(:customer_2_height)
                      booking_line_resource.customer_2_weight = item[:customer_2_weight] if item.has_key?(:customer_2_weight)
                      booking_line_resource.save
                    end
                  end
                end
              rescue DataMapper::SaveFailureError => error
                logger.error "Error updating order. #{@booking.inspect} #{@booking.errors.full_messages.inspect}"
                raise error
              end
            end
            status 200
            content_type :json
            true.to_json
          else
            halt 404
          end

        end

      end
    end
  end
end