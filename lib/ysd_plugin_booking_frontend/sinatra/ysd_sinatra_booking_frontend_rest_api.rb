module Sinatra
  module YitoExtension

    module BookingFrontendRESTApiHelper

      MIDDLE_ENDIAN_LANGUAGES = ['en']

      #
      # Build the shopping representation to be exported to JSON
      #
      def build_shopping_cart(shopping_cart, locale)

        sc = { # Basic data
               free_access_id: shopping_cart.free_access_id,
               date_from: shopping_cart.date_from.strftime('%Y-%m-%d'),
               time_from: shopping_cart.time_from,
               date_to: shopping_cart.date_to.strftime('%Y-%m-%d'),
               time_to: shopping_cart.time_to,
               days: shopping_cart.days,
               customer_name: shopping_cart.customer_name,
               customer_surname: shopping_cart.customer_surname,
               customer_email: shopping_cart.customer_email,
               customer_phone: shopping_cart.customer_phone,
               customer_mobile_phone: shopping_cart.customer_mobile_phone,
               customer_document_id: shopping_cart.customer_document_id,
               customer_language: shopping_cart.customer_language,
               item_cost: shopping_cart.item_cost,
               extras_cost: shopping_cart.extras_cost,
               time_from_cost: shopping_cart.time_from_cost,
               time_to_cost: shopping_cart.time_to_cost,
               product_deposit_cost: shopping_cart.product_deposit_cost,
               total_deposit: shopping_cart.total_deposit,
               total_cost: shopping_cart.total_cost,
               booking_amount: shopping_cart.booking_amount,
               pickup_place_cost: shopping_cart.pickup_place_cost,
               return_place_cost: shopping_cart.return_place_cost,
               promotion_code: shopping_cart.promotion_code,
               comments: shopping_cart.comments,
               destination_accommodation: shopping_cart.destination_accommodation
        }
        sc.merge!({
                      date_from_short_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_from, :short, locale),
                      date_from_default_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_from, :default, locale),
                      date_from_extended_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_from, :extended, locale),
                      date_from_full_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_from, :full, locale).split(' ').map!{|item| item.capitalize}.join(' '),
                      date_to_short_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_to, :short, locale),
                      date_to_default_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_to, :default, locale),
                      date_to_extended_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_to, :extended, locale),
                      date_to_full_format: SystemConfiguration::Settings.instance.format_date(shopping_cart.date_to, :full, locale).split(' ').map!{|item| item.capitalize}.join(' ')
                  })

        sc.merge!({ # Pickup / Return place
                    pickup_place: shopping_cart.pickup_place,
                    pickup_place_customer_translation: shopping_cart.pickup_place_customer_translation,
                    return_place: shopping_cart.return_place,
                    return_place_customer_translation: shopping_cart.return_place_customer_translation
                  })

        sc.merge!({ # Driver information
                    driver_age: shopping_cart.driver_age,
                    driver_driving_license_years: shopping_cart.driver_driving_license_years,
                    driver_under_age: shopping_cart.driver_under_age,
                    driver_age_allowed: shopping_cart.driver_age_allowed,
                    driver_age_cost: shopping_cart.driver_age_cost,
                    driver_age_deposit: shopping_cart.driver_age_deposit,
                    driver_age_rule_id: shopping_cart.driver_age_rule_id,
                    driver_age_rule_description: shopping_cart.driver_age_rule_description,
                    driver_age_rule_description_customer_translation: shopping_cart.driver_age_rule_description_customer_translation
                  })

        # Items
        sc_items = []
        shopping_cart.items.each do |item|
          sc_item = {
              id: item.id,
              item_id: item.item_id,
              item_description: item.item_description,
              item_description_customer_translation: item.item_description_customer_translation,
              item_unit_cost_base: item.item_unit_cost_base,
              item_unit_cost: item.item_unit_cost,
              item_cost: item.item_cost,
              quantity: item.quantity,
              product_deposit_unit_cost: item.product_deposit_unit_cost,
              product_deposit_cost: item.product_deposit_cost
          }
          resources = []
          item.item_resources.each do |item_resource|
            resource = {
                id: item_resource.id,
            }
            resource.merge!({
                                pax: item_resource.pax,
                                resource_user_name: item_resource.resource_user_name,
                                resource_user_surname: item_resource.resource_user_surname,
                                resource_user_document_id: item_resource.resource_user_document_id,
                                resource_user_phone: item_resource.resource_user_phone,
                                resource_user_email: item_resource.resource_user_email,
                                resource_user_2_name: item_resource.resource_user_2_name,
                                resource_user_2_surname: item_resource.resource_user_2_surname,
                                resource_user_2_document_id: item_resource.resource_user_2_document_id,
                                resource_user_2_phone: item_resource.resource_user_2_phone,
                                resource_user_2_email: item_resource.resource_user_2_email
                            })
            resources << resource
          end
          sc_item.store(:item_resources, resources)
          sc_items << sc_item
        end

        sc.merge!(
            items: sc_items
        )

        # Extras
        sc_extras = []
        shopping_cart.extras.each do |extra|
          extra = {
              id: extra.id,
              extra_id: extra.extra_id,
              extra_description: extra.extra_description,
              extra_description_customer_translation: extra.extra_description_customer_translation,
              extra_unit_cost: extra.extra_unit_cost,
              extra_cost: extra.extra_cost,
              quantity: extra.quantity
          }
          sc_extras << extra
        end
        sc.merge!(
            extras: sc_extras
        )

        return sc
      end

      #
      # Build the booking representation to be exported to JSON
      #
      def build_booking(booking, locale)

        booking_summary = { # Basic data
                            id: booking.id,
                            date_from: booking.date_from,
                            date_to: booking.date_to,
                            days: booking.days,
                            customer_name: booking.customer_name,
                            customer_surname: booking.customer_surname,
                            customer_phone: booking.customer_phone,
                            customer_mobile_phone: booking.customer_mobile_phone,
                            customer_email: booking.customer_email,
                            customer_document_id: booking.customer_document_id,
                            customer_language: booking.customer_language,
                            status: booking.status,
                            free_access_id: booking.free_access_id,
                            destination_accommodation: booking.destination_accommodation
        }

        booking_summary.merge!({
                                   date_from_short_format: SystemConfiguration::Settings.instance.format_date(booking.date_from, :short, locale),
                                   date_from_default_format: SystemConfiguration::Settings.instance.format_date(booking.date_from, :default, locale),
                                   date_from_extended_format: SystemConfiguration::Settings.instance.format_date(booking.date_from, :extended, locale),
                                   date_from_full_format: SystemConfiguration::Settings.instance.format_date(booking.date_from, :full, locale),
                                   date_to_short_format: SystemConfiguration::Settings.instance.format_date(booking.date_to, :short, locale),
                                   date_to_default_format: SystemConfiguration::Settings.instance.format_date(booking.date_to, :default, locale),
                                   date_to_extended_format: SystemConfiguration::Settings.instance.format_date(booking.date_to, :extended, locale),
                                   date_to_full_format: SystemConfiguration::Settings.instance.format_date(booking.date_to, :full, locale)
                               })

        booking_summary.merge!({ # Pickup / Return
                                 pickup_place: booking.pickup_place,
                                 pickup_place_customer_translation: booking.pickup_place_customer_translation,
                                 return_place: booking.return_place,
                                 return_place_customer_translation: booking.return_place_customer_translation
                               })

        booking_summary.merge!({ # Time from / to
                                 time_from: booking.time_from,
                                 time_to: booking.time_to
                               })

        booking_summary.merge!({ # Number of adults and children
                                 number_of_adults: booking.number_of_adults,
                                 number_of_children: booking.number_of_children
                               })

        booking_summary.merge!({ # Driver information
                                 driver_name: booking.driver_name,
                                 driver_surname: booking.driver_surname,
                                 driver_document_id: booking.driver_document_id,
                                 driver_date_of_birth: booking.driver_date_of_birth,
                                 driver_age: booking.driver_age,
                                 driver_driving_license_years: booking.driver_driving_license_years,
                                 driver_under_age: booking.driver_under_age,
                                 driver_age_allowed: booking.driver_age_allowed,
                                 driver_age_cost: booking.driver_age_cost,
                                 driver_age_deposit: booking.driver_age_deposit,
                                 driver_age_rule_id: booking.driver_age_rule_id,
                                 driver_age_rule_description: booking.driver_age_rule_description,
                                 driver_age_rule_description_customer_translation: booking.driver_age_rule_description_customer_translation,
                                 driver_driving_license_number: booking.driver_driving_license_number,
                                 driver_driving_license_date: booking.driver_driving_license_date,
                                 driver_driving_license_country: booking.driver_driving_license_country,
                               })

        booking_summary.merge!({ # Flight
                                 flight_company: booking.flight_company,
                                 flight_number: booking.flight_number,
                                 flight_time: booking.flight_time
                               })

        booking_summary.merge!({ # Payment information
                                 payment_status: booking.payment_status,
                                 pay_now: booking.pay_now,
                                 payment_method_id: booking.payment_method_id
                               })

        booking_summary.merge!({ # Basic cost
                                 item_cost: booking.item_cost,
                                 extras_cost: booking.extras_cost,
                                 total_cost: booking.total_cost,
                                 total_paid: booking.total_paid,
                                 total_pending: booking.total_pending
                               })

        booking_summary.merge!({ # Time from / to cost
                                 time_from_cost: booking.time_from_cost,
                                 time_to_cost: booking.time_to_cost
                               })

        booking_summary.merge!({ # Pick up / Return place cost
                                 pickup_place_cost: booking.pickup_place_cost,
                                 return_place_cost: booking.return_place_cost
                               })

        booking_summary.merge!({ # Driver age cost
                                 driver_age_cost: booking.driver_age_cost
                               })

        booking_summary.merge!({ # Product deposit cost
                                 product_deposit_cost: booking.product_deposit_cost,
                                 total_deposit: booking.total_deposit
                               })

        # Lines (products)
        lines = []
        booking.booking_lines.each do |booking_line|
          line = {
              id: booking_line.id,
              item_id: booking_line.item_id,
              item_description: booking_line.item_description,
              item_description_customer_translation: booking_line.item_description_customer_translation,
              item_unit_cost_base: booking_line.item_unit_cost_base,
              item_unit_cost: booking_line.item_unit_cost,
              item_cost: booking_line.item_cost,
              quantity: booking_line.quantity,
              product_deposit_unit_cost: booking_line.product_deposit_unit_cost,
              product_deposit_cost: booking_line.product_deposit_cost
          }
          resources = []
          booking_line.booking_line_resources.each do |booking_line_resource|
            resource = {
                id: booking_line_resource.id,
                booking_item_category: booking_line_resource.booking_item_category
            }
            resource.merge!({
                                booking_item_reference: booking_line_resource.booking_item_reference,
                                booking_item_stock_model: booking_line_resource.booking_item_stock_model,
                                booking_item_stock_plate: booking_line_resource.booking_item_stock_plate,
                                booking_item_characteristic_1: booking_line_resource.booking_item_characteristic_1,
                                booking_item_characteristic_2: booking_line_resource.booking_item_characteristic_2,
                                booking_item_characteristic_3: booking_line_resource.booking_item_characteristic_3,
                                booking_item_characteristic_4: booking_line_resource.booking_item_characteristic_4
                            })
            resource.merge!({
                                pax: booking_line_resource.pax,
                                resource_user_name: booking_line_resource.resource_user_name,
                                resource_user_surname: booking_line_resource.resource_user_surname,
                                resource_user_document_id: booking_line_resource.resource_user_document_id,
                                resource_user_phone: booking_line_resource.resource_user_phone,
                                resource_user_email: booking_line_resource.resource_user_email,
                                resource_user_2_name: booking_line_resource.resource_user_2_name,
                                resource_user_2_surname: booking_line_resource.resource_user_2_surname,
                                resource_user_2_document_id: booking_line_resource.resource_user_2_document_id,
                                resource_user_2_phone: booking_line_resource.resource_user_2_phone,
                                resource_user_2_email: booking_line_resource.resource_user_2_email
                            })
            resources << resource
          end
          line.store(:booking_line_resources, resources)
          lines << line
        end
        booking_summary.merge!(
            booking_lines: lines
        )

        # Extras
        extras = []
        booking.booking_extras.each do |booking_extra|
          extra = {
              id: booking_extra.id,
              extra_id: booking_extra.extra_id,
              extra_description: booking_extra.extra_description,
              extra_description_customer_translation: booking_extra.extra_description_customer_translation,
              extra_unit_cost: booking_extra.extra_unit_cost,
              extra_cost: booking_extra.extra_cost,
              quantity: booking_extra.quantity
          }
          extras << extra
        end
        booking_summary.merge!(
            booking_extras: extras
        )

        booking_summary.merge!(
            summary_status: "#{booking.customer_name} #{booking.customer_surname}, <strong>#{t.booking.title(t[:booking][:state][booking.status.to_sym]).to_s.downcase}</strong>"
        )
      end

      #
      # Build the shopping cart (with products and extras) to be served
      #
      def shopping_cart_to_json(shopping_cart)

        locale = session[:locale]#locale_to_translate_into
        booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))

        # Prepare the shopping cart
        sc = build_shopping_cart(shopping_cart, locale)
        sc_json = sc.to_json

        # Prepare the products
        renting_search_options = {locale: locale,
                                  full_information: booking_item_family.frontend == :shopcart,
                                  product_code: nil, # All products
                                  web_public: true,
                                  sales_channel_code: shopping_cart.sales_channel_code}
        p_json = ::Yito::Model::Booking::BookingCategory.search(shopping_cart.date_from, shopping_cart.date_to,
                                                                shopping_cart.days, renting_search_options).to_json

        # Prepare the extras
        e_json = ::Yito::Model::Booking::RentingExtraSearch.search(shopping_cart.date_from,
                                                                   shopping_cart.date_to, shopping_cart.days, locale).to_json

        # Prepare the sales process
        #
        # TODO : Take into account sales channel payment configuration
        #
        if shopping_cart.sales_channel_code.nil? or shopping_cart.sales_channel_code.empty?
            can_pay = SystemConfiguration::Variable.get_value('booking.payment','false').to_bool &&
                      BookingDataSystem::Booking.payment_cadence?(shopping_cart.date_from, shopping_cart.time_from)
        else
          can_pay = false
        end
        server_timestamp = DateTime.now
        sales_process = {can_pay: can_pay, server_date: server_timestamp.strftime('%Y-%m-%d'), server_time: server_timestamp.strftime('%H:%M')}
        sales_process_json = sales_process.to_json

        # Join all the data togheter
        "{\"shopping_cart\": #{sc_json}, \"products\": #{p_json}, \"extras\": #{e_json}, \"sales_process\": #{sales_process_json} }"


      end

      #
      # Build the booking (with products and extras) to be served
      #
      def booking_to_json(booking)

        locale = session[:locale]#locale_to_translate_into

        # Prepare the booking/reservation
        booking_summary = build_booking(booking, locale)
        booking_summary_json = booking_summary.to_json

        # Prepare the products
        domain = SystemConfiguration::Variable.get_value('site.domain')
        products = ::Yito::Model::Booking::BookingCategory.all(fields: [:code, :name, :short_description, :description, :album_id],
                                                               conditions: {active: true}, order: [:code])
        products_list = []
        products.each do |item|
          products_list << {
              code: item.code, name: item.name, short_description: item.short_description, description: item.description,
              photo: item.photo_url_medium.match(/^https?:/) ? item.photo_url_medium : File.join(domain, item.photo_url_medium),
              full_photo:  item.photo_url_full.match(/^https?:/) ? item.photo_url_full : File.join(domain, item.photo_url_full)
          }
        end
        p_json = products_list.to_json

        # Prepare the sales process
        sales_process = {can_pay: booking.can_pay?}
        sales_process_json = sales_process.to_json

        # Join all the data togheter
        "{\"booking\": #{booking_summary_json}, \"products\": #{p_json}, \"sales_process\": #{sales_process_json} }"

      end

      #
      # Parses dd/mm/yyyy date
      #
      def parse_date(date_str, language=nil)
        p "date: #{date_str} language: #{language}"
        if date_str.nil?
          return nil
        elsif /\d{2}\/\d{2}\/\d{4}/.match(date_str) # Little endian / Middle endian date format
          if language and MIDDLE_ENDIAN_LANGUAGES.include?(language)
            return DateTime.strptime(date_str,'%m/%d/%Y')
          else
            return DateTime.strptime(date_str,'%d/%m/%Y')
          end
        elsif /\d{4}\/\d{2}\/\d{2}/.match(date_str) # Big endian date format
          return DateTime.strptime(date_str,'%Y/%m/%d')
        else
          begin
            return DateTime.parse(date_str)
          rescue ArgumentError
            logger.error "Invalid date #{date_str}"
            return nil
          end
        end
      end

      #
      # Calculates age
      #
      def age(date_of_reference, date_of_birth)

        if date_of_reference.nil? || (date_of_reference.is_a?String and date_of_reference.empty?) ||
            date_of_birth.nil? || (date_of_birth.is_a?String and date_of_birth.empty?)
          return nil
        else
          (date_of_reference.year-date_of_birth.year) + (date_of_birth.month>date_of_reference.month ? 1:0)
        end

      end

    end

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
            {id: item.name, name: item_translation.name}
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
            {id: item.name, name: item_translation.name}
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
            #setup_session_locale_from_params
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
            shopping_cart.driver_date_of_birth = parse_date(request_data['driver_date_of_birth'], shopping_cart.customer_language)  if request_data.has_key?('driver_date_of_birth')
            shopping_cart.driver_driving_license_number = request_data['driver_driving_license_number'] if request_data.has_key?('driver_driving_license_number')
            shopping_cart.driver_driving_license_date = parse_date(request_data['driver_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_date')
            shopping_cart.driver_driving_license_country = request_data['driver_driving_license_country'] if request_data.has_key?('driver_driving_license_country')
            shopping_cart.driver_driving_license_expiration_date = parse_date(request_data['driver_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('driver_driving_license_expiration_date')
            shopping_cart.calculate_cost # Calculate cost using driver real date of birth and driving license date
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
            shopping_cart.additional_driver_1_document_id_date = parse_date(request_data['additional_driver_1_document_id_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_document_id_date')
            shopping_cart.additional_driver_1_document_id_expiration_date = parse_date(request_data['additional_driver_1_document_id_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_document_id_expiration_date')
            shopping_cart.additional_driver_1_origin_country = request_data['additional_driver_1_origin_country'] if request_data.has_key?('additional_driver_1_origin_country')
            shopping_cart.additional_driver_1_date_of_birth = parse_date(request_data['additional_driver_1_date_of_birth'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_date_of_birth')
            shopping_cart.additional_driver_1_age = age(Date.today, shopping_cart.additional_driver_1_date_of_birth) if !shopping_cart.additional_driver_1_date_of_birth.nil?
            shopping_cart.additional_driver_1_driving_license_number = request_data['additional_driver_1_driving_license_number'] if request_data.has_key?('additional_driver_1_driving_license_number')
            shopping_cart.additional_driver_1_driving_license_date = parse_date(request_data['additional_driver_1_driving_license_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_driving_license_date')
            shopping_cart.additional_driver_1_driving_license_country = request_data['additional_driver_1_driving_license_country'] if request_data.has_key?('additional_driver_1_driving_license_country')
            shopping_cart.additional_driver_1_driving_license_expiration_date = parse_date(request_data['additional_driver_1_driving_license_expiration_date'], shopping_cart.customer_language) if request_data.has_key?('additional_driver_1_driving_license_expiration_date')
            shopping_cart.additional_driver_1_phone = request_data['additional_driver_1_phone'] if request_data.has_key?('additional_driver_1_phone')
            shopping_cart.additional_driver_1_email = request_data['additional_driver_1_email'] if request_data.has_key?('additional_driver_1_email')
            # Flight
            shopping_cart.flight_company = request_data['flight_company'] if request_data.has_key?('flight_company')
            shopping_cart.flight_number = request_data['flight_number'] if request_data.has_key?('flight_number')
            shopping_cart.flight_time = request_data['flight_time'] if request_data.has_key?('flight_time')

            begin
              shopping_cart.save
            rescue DataMapper::SaveFailureError => error
              logger.error "Error saving shopping_cart #{error}"
              logger.error "Error details: #{error.resource.errors.full_messages.inspect}"
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

          p "shopping cart : #{session[:shopping_cart_renting_id]}"

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
              driver_age_rule_id = sales_channel_code = nil

          if model_request[:date_from] && model_request[:date_to]
            date_from = DateTime.strptime(model_request[:date_from],"%d/%m/%Y")
            time_from = model_request[:time_from]
            date_to = DateTime.strptime(model_request[:date_to],"%d/%m/%Y")
            time_to = model_request[:time_to]
            pickup_place = model_request[:pickup_place] if model_request.has_key?(:pickup_place)
            return_place = model_request[:return_place] if model_request.has_key?(:return_place)
            number_of_adults = model_request[:number_of_adults] if model_request.has_key?(:number_of_adults)
            number_of_children = model_request[:number_of_children] if model_request.has_key?(:number_of_childen)
            driver_age_rule_id = model_request[:driver_age_rule] if model_request.has_key?(:driver_age_rule)
            sales_channel_code = model_request[:sales_channel_code] if model_request.has_key?(:sales_channel_code)
            sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?
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
                                                pickup_place, return_place,
                                                number_of_adults, number_of_children,
                                                driver_age_rule_id, sales_channel_code)
            if shopping_cart.customer_language != session[:locale]
              shopping_cart.change_customer_language(session[:locale])
            end
          else
            booking_pickup_place = ::Yito::Model::Booking::PickupReturnPlace.first(name: pickup_place)
            booking_return_place = ::Yito::Model::Booking::PickupReturnPlace.first(name: return_place)
            shopping_cart =::Yito::Model::Booking::ShoppingCartRenting.create(
                date_from: date_from, time_from: time_from,
                date_to: date_to, time_to: time_to,
                pickup_place: pickup_place,
                pickup_place_customer_translation: booking_pickup_place ? booking_pickup_place.translate(session[:locale]).name : pickup_place,
                return_place: return_place,
                return_place_customer_translation: booking_return_place ? booking_return_place.translate(session[:locale]).name : return_place,
                number_of_adults: number_of_adults,
                number_of_children: number_of_children,
                driver_age_rule_id: driver_age_rule_id,
                sales_channel_code: sales_channel_code,
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

      end
    end
  end
end