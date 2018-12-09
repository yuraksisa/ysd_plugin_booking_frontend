module Sinatra
  module YitoExtension

    module BookingFrontendRESTApi

      def self.registered(app)

        # ------------------- Querying -------------------------------------------------------------------------

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
                      pickup_return_places_same_rental_location: BookingDataSystem::Booking.pickup_return_places_same_rental_location,
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
            {id: item.name, name: item_translation.name, price: item.price, rental_location_code: item.rental_location_code}
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
            {id: item.name, name: item_translation.name, price: item.price, rental_location_code: item.rental_location_code}
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

        # =============================== PRODUCTS INFORMATION =============================================

        #
        # Get the products
        #
        # Parameters:
        #
        # * For pagination
        # - offset [from the item]
        # - limit  [# of items]
        #
        # * To order
        # - order [column]
        #
        # Result:
        #
        # {"total":2,
        #  "offset":1,
        #  "limit":1,
        #  "data":[{"code":"K2","name":"Kayak doble","short_description":"Kayak doble",
        #           "description":"<p>Kayak Doble</p>","from_price":"0.0","from_price_offer":"0.0",
        #           "photo_path":"https://demo-kayak.mybooking.es/uploads/5/36/55/medium/kayak-doble.png",
        #           "full_photo_path":"https://demo-kayak.mybooking.es/uploads/5/36/55/kayak-doble.png"}]}
        #
        app.get '/api/booking/frontend/products' do

          offset = params[:offset].to_i
          limit = params[:limit].to_i
          if limit == 0
            limit = 20
          end

          order = if params[:order]
                    [params[:order]]
                  else
                    [:code]
                  end
          conditions = {active: true, web_public: true}

          domain = SystemConfiguration::Variable.get_value('site.domain')
          total = ::Yito::Model::Booking::BookingCategory.count(conditions: conditions)
          data = ::Yito::Model::Booking::BookingCategory.all(
              fields: [:code, :name, :short_description, :description, :from_price, :from_price_offer],
              conditions: conditions,
              order: order,
              offset: offset,
              limit: limit).map do |item|

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

          result = {total: total, offset: offset, limit: limit, data: data}

          content_type :json
          result.to_json

        end


        #
        # Get a product detail
        #
        # Result
        #
        # {"code":"K2","name":"Kayak doble","short_description":"Kayak doble",
        #  "description":"<p>Kayak Doble</p>",
        #  "from_price":"0.0","from_price_offer":"0.0",
        #  "photo_path":"https://demo-kayak.mybooking.es/uploads/5/36/55/medium/kayak-doble.png",
        #  "full_photo_path":"https://demo-kayak.mybooking.es/uploads/5/36/55/kayak-doble.png"}
        #
        app.get '/api/booking/frontend/products/:id' do

          if product = ::Yito::Model::Booking::BookingCategory.get(params[:id])

            # Build the photo
            domain = SystemConfiguration::Variable.get_value('site.domain')
            photo = product.album ? product.album.thumbnail_medium_url : nil
            full_photo = product.album ? product.album.image_url : nil
            photo_path = nil
            if photo
              photo_path = (photo.match(/^https?:/) ? photo : File.join(domain, photo))
            end
            full_photo_path = nil
            if full_photo
              full_photo_path = (full_photo.match(/^https?:/) ? full_photo : File.join(domain, full_photo))
            end

            # Build the data
            data = {code: product.code, name: product.name,
             short_description: product.short_description, description: product.description,
             from_price: product.from_price, from_price_offer: product.from_price_offer,
             photo_path: photo_path, full_photo_path: full_photo_path}

            content_type :json
            data.to_json

          else
            status 404
          end

        end

        #
        # Get a product availability for a period [Use to ensure reservation of category of resources product - 1 to n -]
        #
        # Parameters:
        #
        # * Period
        # - from
        # - time_from
        # - to
        # - time_to
        # * Others
        # - sales_channel
        #
        # Result:
        #
        #  {"code":"K2","name":"Kayak doble","short_description":"Kayak doble",
        #   "description":"<p>Kayak Doble</p>",
        #   "photo":"https://demo-kayak.mybooking.es/uploads/5/36/55/medium/kayak-doble.png",
        #   "full_photo":"https://demo-kayak.mybooking.es/uploads/5/36/55/kayak-doble.png",
        #   "base_price":"603.0",
        #   "price":"603.0",
        #   "deposit":"0.0",
        #   "availability":true,
        #   "payment_availibility":true,
        #   "stock":4,
        #   "busy":0}}
        #
        app.get '/api/booking/frontend/products/:id/availability' do

          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          date_from = params[:from]
          time_from = params[:time_from]
          date_to = params[:to]
          time_to = params[:time_to]
          unless date_from.nil?
            date_from = Date.parse(date_from)
          end
          unless date_to.nil?
            date_to = Date.parse(date_to)
          end
          time_from ||= booking_item_family.time_start
          time_to ||= booking_item_family.time_end

          if date_from.nil? or date_to.nil?
            halt 422, 'date_from or date_to not assigned'
          end

          days = BookingDataSystem::Booking.calculate_days(date_from, time_from, date_to, time_to)[:days]

          sales_channel = params[:sales_channel]
          rental_location_code = params[:rental_location_code]

          if product = ::Yito::Model::Booking::BookingCategory.get(params[:id])
            search = ::Yito::Model::Booking::BookingCategory.search(rental_location_code,
                                                                    date_from,
                                                                    time_from,
                                                                    date_to,
                                                                    time_to,
                                                                    days,
                                                                    {
                                                                        locale: session[:locale],
                                                                        full_information: true,
                                                                        product_code: product.code,
                                                                        web_public: true,
                                                                        sales_channel_code: sales_channel,
                                                                        apply_promotion_code: false,
                                                                        promotion_code: nil
                                                                    })

            content_type :json
            {data: search}.to_json
          else
            status 404
          end

        end

        #
        # Get a product occupation detail for a period [Use to check information for resource category - 1 to 1 - ]
        #
        # Parameters:
        #
        # * Period
        # - from
        # - time_from
        # - to
        # - time_to
        #
        # Result
        #
        # {"occupation":{"2018-Dic-25":{"free":true,"available":4},
        #                "2018-Dic-26":{"free":true,"available":4}}
        #
        app.get '/api/booking/frontend/products/:id/occupation' do

          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

          date_from = params[:from]
          date_to = params[:to]

          today = Date.today
          if date_from.nil?
            date_from ||= (today - 10)
          else
            date_from = Date.parse(date_from)
          end
          if date_to.nil?
            date_to ||= (today + 10)
          else
            date_to = Date.parse(date_to)
          end

          if product = ::Yito::Model::Booking::BookingCategory.get(params[:id])
            occupation = {}
            BookingDataSystem::Booking.category_daily_detailed_period_occupation(date_from, date_to, product.code)[product.code].each do |key, value|
              occupation[key] = {free: (value[:occupied] < value[:total]), available: (value[:total] - value[:occupied])} unless key == :total
            end

            content_type :json
            {occupation: occupation}.to_json
          else
            status 404
          end

        end

        # =============================== SHOPPING CART =============================================

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

        #
        # Confirm reservation : CHECKOUT
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

          # Create the order from the shopping cart
          if shopping_cart
            shopping_cart.transaction do
              booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
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
              if booking_item_family and booking_item_family.driver
                shopping_cart.driver_name = request_data['driver_name'] if request_data.has_key?('driver_name')
                shopping_cart.driver_surname = request_data['driver_surname']  if request_data.has_key?('driver_surname')
                shopping_cart.driver_document_id = request_data['driver_document_id'] if request_data.has_key?('driver_document_id')
                shopping_cart.driver_date_of_birth = parse_date(request_data['driver_date_of_birth'], shopping_cart.customer_language)  if request_data.has_key?('driver_date_of_birth') and !request_data['driver_date_of_birth'].nil? and !request_data['driver_date_of_birth'].to_s.empty?
                shopping_cart.driver_driving_license_number = request_data['driver_driving_license_number'] if request_data.has_key?('driver_driving_license_number')
                shopping_cart.driver_driving_license_date = parse_date(request_data['driver_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_date') and !request_data['driver_driving_license_date'].nil? and !request_data['driver_driving_license_date'].to_s.empty?
                shopping_cart.driver_driving_license_country = request_data['driver_driving_license_country'] if request_data.has_key?('driver_driving_license_country')
                shopping_cart.driver_driving_license_expiration_date = parse_date(request_data['driver_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_expiration_date') and !request_data['driver_driving_license_expiration_date'].nil? and !request_data['driver_driving_license_expiration_date'].to_s.empty?
                if booking_item_family and booking_item_family.driver_date_of_birth
                  shopping_cart.driver_age = BookingDataSystem::Booking.completed_years(shopping_cart.date_from,
                                                                                        shopping_cart.driver_date_of_birth) unless shopping_cart.driver_date_of_birth.nil?
                end
                if booking_item_family and booking_item_family.driver_license
                  shopping_cart.driver_driving_license_years = BookingDataSystem::Booking.completed_years(shopping_cart.date_from,
                                                                                                          shopping_cart.driver_driving_license_date) unless shopping_cart.driver_driving_license_date.nil?
                end
                shopping_cart.calculate_cost(true, true) # Calculate cost using driver real date of birth and driving license date
              end
              # Address
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
              if booking_item_family and booking_item_family.driver_license
                # Aditional driver 1
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
                # Additional driver 2
                shopping_cart.additional_driver_2_name = request_data['additional_driver_2_name'] if request_data.has_key?('additional_driver_2_name')
                shopping_cart.additional_driver_2_surname = request_data['additional_driver_2_surname'] if request_data.has_key?('additional_driver_2_surname')
                shopping_cart.additional_driver_2_document_id = request_data['additional_driver_2_document_id'] if request_data.has_key?('additional_driver_2_document_id')
                shopping_cart.additional_driver_2_document_id_date = parse_date(request_data['additional_driver_2_document_id_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_2_document_id_date') and !request_data['additional_driver_2_document_id_date'].nil? and !request_data['additional_driver_2_document_id_date'].to_s.empty?
                shopping_cart.additional_driver_2_document_id_expiration_date = parse_date(request_data['additional_driver_2_document_id_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_2_document_id_expiration_date') and !request_data['additional_driver_2_document_id_expiration_date'].nil? and !request_data['additional_driver_2_document_id_expiration_date'].to_s.empty?
                shopping_cart.additional_driver_2_origin_country = request_data['additional_driver_2_origin_country'] if request_data.has_key?('additional_driver_2_origin_country')
                shopping_cart.additional_driver_2_date_of_birth = parse_date(request_data['additional_driver_2_date_of_birth'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_2_date_of_birth') and !request_data['additional_driver_2_date_of_birth'].nil? and !request_data['additional_driver_2_date_of_birth'].to_s.empty?
                shopping_cart.additional_driver_2_age = age(Date.today, shopping_cart.additional_driver_2_date_of_birth) if !shopping_cart.additional_driver_2_date_of_birth.nil?
                shopping_cart.additional_driver_2_driving_license_number = request_data['additional_driver_2_driving_license_number'] if request_data.has_key?('additional_driver_2_driving_license_number')
                shopping_cart.additional_driver_2_driving_license_date = parse_date(request_data['additional_driver_2_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_2_driving_license_date') and !request_data['additional_driver_2_driving_license_date'].nil? and !request_data['additional_driver_2_driving_license_date'].to_s.empty?
                shopping_cart.additional_driver_2_driving_license_country = request_data['additional_driver_2_driving_license_country'] if request_data.has_key?('additional_driver_2_driving_license_country')
                shopping_cart.additional_driver_2_driving_license_expiration_date = parse_date(request_data['additional_driver_2_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_2_driving_license_expiration_date') and !request_data['additional_driver_2_driving_license_expiration_date'].nil? and !request_data['additional_driver_2_driving_license_expiration_date'].to_s.empty?
                shopping_cart.additional_driver_2_phone = request_data['additional_driver_2_phone'] if request_data.has_key?('additional_driver_2_phone')
                shopping_cart.additional_driver_2_email = request_data['additional_driver_2_email'] if request_data.has_key?('additional_driver_2_email')
              end
              # Flight
              if booking_item_family and booking_item_family.flight
                shopping_cart.flight_airport_origin = request_data['flight_airport_origin'] if request_data.has_key?('flight_airport_origin')
                shopping_cart.flight_company = request_data['flight_company'] if request_data.has_key?('flight_company')
                shopping_cart.flight_number = request_data['flight_number'] if request_data.has_key?('flight_number')
                shopping_cart.flight_time = request_data['flight_time'] if request_data.has_key?('flight_time')
                shopping_cart.flight_airport_destination = request_data['flight_airport_destination'] if request_data.has_key?('flight_airport_destination')
                shopping_cart.flight_company_departure = request_data['flight_company_departure'] if request_data.has_key?('flight_company_departure')
                shopping_cart.flight_number_departure = request_data['flight_number_departure'] if request_data.has_key?('flight_number_departure')
                shopping_cart.flight_time_departure = request_data['flight_time_departure'] if request_data.has_key?('flight_time_departure')
              end
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
            end
          else
            logger.error "Shopping cart does not exist"
            content_type 'json'
            status 404
            {error: 'Shopping cart not found'}.to_json
          end

        end

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
            return_place, custom_return_place, return_place_customer_translation, rental_location_code = request_pickup_return_place(model_request)
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

        # =============================== RESERVATION =============================================

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
              # Updates the booking
              update_booking_from_request(model_request)
            end
            # Prepare response
            status 200
            content_type :json
            true.to_json
          else
            halt 404
          end

        end

        #
        # Reservation confirm (step 2) : Only for mybooking instances that uses confirmation step 2
        #
        app.put '/api/booking/frontend/booking/:free_access_id/confirm' do

          if SystemConfiguration::Variable.get_value('booking.frontend.confirmation_step_2', 'false').to_bool

            # Extract the data parameters
            begin
              request.body.rewind
              model_request = JSON.parse(URI.unescape(request.body.read)).symbolize_keys!
            rescue JSON::ParserError
              halt 422, {error: 'Invalid request. Expected a JSON with data params'}.to_json
            end

            if @booking = BookingDataSystem::Booking.get_by_free_access_id(params[:free_access_id])
              @booking.transaction do
                # Updates the booking
                update_booking_from_request(model_request)
                # Confirm the reservation
                @booking.confirm!
              end
              # Prepare response
              status 200
              content_type :json
              booking_to_json(@booking)
            else
              halt 404
            end


          else
            halt 404
          end

        end

      end
    end
  end
end