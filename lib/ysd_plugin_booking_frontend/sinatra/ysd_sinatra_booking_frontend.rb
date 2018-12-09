module Sinatra
  module YitoExtension
    module BookingFrontend

      def self.registered(app)

		app.settings.views = Array(app.settings.views).push(
				File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..',
																	 'views')))
		app.settings.translations = Array(app.settings.translations).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'i18n')))

		app.set :bookingcharge_gateway_return_ok, '/reserva/payment-gateway-return/ok'
		app.set :bookingcharge_gateway_return_cancel, '/reserva/payment-gateway-return/cancel'
		app.set :bookingcharge_gateway_return_nok, '/reserva/payment-gateway-return/nok'

		# =================== PRODUCTS =================================================================

		#
		# Step 1 - B : Products
		#
		app.route :get, :post, ['/reserva/productos', '/book/products'] do

		end

		#
		# Step 2 - B : Product
		#
		app.route :get, :post, ['/reserva/producto/:id', 'book/product/:id'] do

		end

  		# =================== RESERVATION PROCESS (FRONT-END) ==========================================

      	#
      	# Step 1 in reservation : choose product
      	#
      	app.route :get, :post, ['/reserva/producto', '/book/product'] do

		  	# Retrive the parameters from the request
			booking_parameters = false
			params.symbolize_keys!
			if params[:date_from] && params[:date_to]
              # Retrieve date/time from - to
      	  	  date_from = DateTime .strptime(params[:date_from],"%d/%m/%Y")
      	  	  time_from = params[:time_from]
      	  	  date_to = DateTime.strptime(params[:date_to],"%d/%m/%Y")
      	  	  time_to = params[:time_to]
              # Retrieve pickup/return place
			  pickup_place, custom_pickup_place, pickup_place_customer_translation,
			  return_place, custom_return_place, return_place_customer_translation,rental_location_code = request_pickup_return_place(params)
			  # Retrieve number of adutls and children
			  number_of_adults = params[:number_of_adults]
			  number_of_children = params[:number_of_children]
			  # Retrieve driver age rule
			  driver_age_rule_id = params[:driver_age_rule]
			  # Retrieve sales channel
			  sales_channel_code = params[:sales_channel_code]
			  sales_channel_code = nil if sales_channel_code and sales_channel_code.empty?
			  # Retrieve promotion code
			  promotion_code = params[:promotion_code]
			  promotion_code = nil if promotion_code and promotion_code.empty?
			  booking_parameters = true
			end

      	  	# Retrieve or create a new shopping cart
      	  	@shopping_cart = nil

			if session.has_key?(:shopping_cart_renting_id)
      	  	  @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.get(session[:shopping_cart_renting_id])
			end

			if @shopping_cart.nil?
				if booking_parameters
      	  		    @shopping_cart = ::Yito::Model::Booking::ShoppingCartRenting.create(
      	  	  					date_from: date_from, time_from: time_from,
      	  	  					date_to: date_to, time_to: time_to,
								pickup_place: pickup_place,
								pickup_place_customer_translation: pickup_place_customer_translation,
								custom_pickup_place: custom_pickup_place,
								return_place: return_place,
								return_place_customer_translation: return_place_customer_translation,
								custom_return_place: custom_return_place,
								number_of_adults: number_of_adults, number_of_children: number_of_children,
								driver_age_rule_id: driver_age_rule_id,
								sales_channel_code: sales_channel_code,
								promotion_code: promotion_code)
				else
					# TODO create default values or redirect home?
				end
      	  	  	session[:shopping_cart_renting_id] = @shopping_cart.id
			else
				if booking_parameters
					@shopping_cart.change_selection_data(
										date_from, time_from,
										date_to, time_to,
										pickup_place, custom_pickup_place,
										return_place, custom_return_place,
										number_of_adults, number_of_children,
										driver_age_rule_id, sales_channel_code, promotion_code)
				end
			end

			# Prepare response
			booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
            locals = {}
            locals.store(:booking_min_days,
            SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
            locals.store(:booking_item_family, booking_item_family)
            locals.store(:booking_item_type,
            SystemConfiguration::Variable.get_value('booking.item_type'))
			locals.store(:pickup_return_places_configuration,
						SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))
			locals.store(:booking_driver_min_age_rules,
						SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)
			locals.store(:custom_pickup_return_place_price, SystemConfiguration::Variable.get_value('booking.custom_pickup_return_place_price', '0').to_i)
			locals.store(:pickup_return_places_same_rental_location, BookingDataSystem::Booking.pickup_return_places_same_rental_location)

      	  	# Load the page
			title = booking_item_family.multiple_items? ? t.front_end_reservation.choose_products_page_title : t.front_end_reservation.choose_product_page_title

			page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_choose_product" : :rent_reservation_choose_product
			page_options = {page_title: title, locals: locals, cache: false}

			default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
			page_options.store(:custom_js, 'rent_reservation_choose_product') unless default_js

      	    load_page(page, page_options)

        end

		#
		# Step 2 : Fill reservation form
		#
        ['/reserva/completar', '/book/complete'].each do |endpoint|
      	  app.get endpoint do

			locals = {}
			locals.store(:booking_item_family,
									 ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
			locals.store(:booking_item_type,
									 SystemConfiguration::Variable.get_value('booking.item_type'))
			locals.store(:total_cost_includes_deposit,
									 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
			locals.store(:booking_driver_min_age_rules,
									 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

			@payment_methods = Payments::PaymentMethod.available_to_web
			@deposit = SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i
			@currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')

			# Load the page
            title = t.front_end_reservation.complete_reservation_page_title

			page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_complete" : :rent_reservation_complete
            page_options = {page_title: title, locals: locals, cache: false}

            default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
            page_options.store(:custom_js, 'rent_reservation_complete') unless default_js

      	  	load_page(page, page_options)

      	  end
      	end

		#
		# Step 3* : Payment [OPTIONAL]
		#
		# It receives three arguments in POST form
		#
		# id: The booking free access id
		# payment: deposit, total or pending
		# payment_method_id: The payment method identifier
		#
		['/reserva/pagar', '/book/pay'].each do |endpoint|
			app.post endpoint do #, :allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do

				if booking = BookingDataSystem::Booking.get_by_free_access_id(params[:id])
					payment = params[:payment]
					payment_method = params[:payment_method_id]
					if charge = booking.create_online_charge!(payment, payment_method)
						session[:booking_id] = booking.id
						session[:charge_id] = charge.id
						status, header, body = call! env.merge("PATH_INFO" => "/charge",
																									 "REQUEST_METHOD" => 'GET')
					else
						status 404 # Charge not created
					end
				else
					status 404
				end

			end
      	end

		#
		# Step 4 : Reservation summary
		#
		['/reserva/:id', '/book/:id'].each do |endpoint|
			app.get endpoint do

				if @booking = BookingDataSystem::Booking.get_by_free_access_id(params[:id])
					# If the reservation customer language does not match with the session locale, redirect to the
					# language url to show the reservation in the customer language
					if settings.multilanguage_site and @booking.customer_language and @booking.customer_language != session[:locale] and
					   @booking.customer_language != settings.default_language
						redirect "/#{@booking.customer_language}#{request.path}"
					end
					locals = {}
					locals.store(:total_cost_includes_deposit,
											 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
					locals.store(:booking_driver_min_age_rules,
											 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

					@payment_methods = Payments::PaymentMethod.available_to_web
					@deposit = SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i
					@currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
					@booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
					@payment = if @booking.can_pay_deposit?
									'deposit'
							   elsif @booking.can_pay_pending?
									'pending'
							   elsif @booking.can_pay_total?
									'total'
							   else
									''
							   end
					# Load the page
		            title = t.front_end_reservation.summary_page_title(@booking.id)
					page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_summary" : :rent_reservation_summary
		            page_options = {page_title: title, locals: locals, cache: false}

		            default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
		            page_options.store(:custom_js, 'rent_reservation_summary') unless default_js

		            load_page(page, page_options)

				else
					status 404
				end

			end
		end

		# =============== RETURN FROM PAYMENT GATEWAY ===================================

		#
		# Return OK from payment gateway
		#
		['/reserva/payment-gateway-return/ok'].each do |endpoint|
			app.get endpoint do

				if session.has_key?(:charge_id)
					@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
					locals = {}
					locals.store(:total_cost_includes_deposit,
											 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
					locals.store(:booking_driver_min_age_rules,
											 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

					@payment_methods = Payments::PaymentMethod.available_to_web
					@deposit = SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i
					@currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
					@booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
					@payment = if @booking.can_pay_deposit?
								 'deposit'
							   elsif @booking.can_pay_pending?
								 'pending'
							   elsif @booking.can_pay_total?
								 'total'
							   end
					# Load the page
		            title = t.front_end_reservation.summary_page_title(@booking.id)
		            page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_summary" : :rent_reservation_summary
		            page_options = {page_title: title, locals: locals, cache: false}
		            default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
		            page_options.store(:custom_js, 'rent_reservation_summary') unless default_js
		            load_page(page, page_options)

				else
					status 404
				end

			end
		end

		#
		# Return CANCEL from payment gateway
		#
		['/reserva/payment-gateway-return/cancel'].each do |endpoint|
			app.get endpoint do
				if session.has_key?(:charge_id)
					@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
					locals = {}
					locals.store(:total_cost_includes_deposit,
											 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
					locals.store(:booking_driver_min_age_rules,
											 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

					@payment_methods = Payments::PaymentMethod.available_to_web
					@deposit = SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i
					@currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
					@booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
					@payment = if @booking.can_pay_deposit?
								 'deposit'
							   elsif @booking.can_pay_pending?
								 'pending'
							   elsif @booking.can_pay_total?
								 'total'
							   end
					# Load the page
					title = t.front_end_reservation.summary_page_title(@booking.id)
					page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_summary" : :rent_reservation_summary
					page_options = {page_title: title, locals: locals, cache: false}
					default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
					page_options.store(:custom_js, 'rent_reservation_summary') unless default_js
					load_page(page, page_options)
				else
					status 404
				end
			end
		end

		#
		# Return NOK from payment gateway
		#
		['/reserva/payment-gateway-return/nok'].each do |endpoint|
			app.get endpoint do
				if session.has_key?(:charge_id)
					@booking = BookingDataSystem::BookingCharge.booking_from_charge(session[:charge_id])
					locals = {}
					locals.store(:total_cost_includes_deposit,
											 SystemConfiguration::Variable.get_value('booking.total_cost_includes_deposit', 'false').to_bool)
					locals.store(:booking_driver_min_age_rules,
											 SystemConfiguration::Variable.get_value('booking.driver_min_age.rules','false').to_bool)

					@payment_methods = Payments::PaymentMethod.available_to_web
					@deposit = SystemConfiguration::Variable.get_value('booking.deposit', '0').to_i
					@currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
					@booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
					@payment = if @booking.can_pay_deposit?
								 'deposit'
							   elsif @booking.can_pay_pending?
								 'pending'
							   elsif @booking.can_pay_total?
								 'total'
							   end
					# Load the page
					title = t.front_end_reservation.summary_page_title(@booking.id)
					page = settings.frontend_skin ? "#{settings.frontend_skin}_rent_reservation_summary" : :rent_reservation_summary
					page_options = {page_title: title, locals: locals, cache: false}
					default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
					page_options.store(:custom_js, 'rent_reservation_summary') unless default_js
					load_page(page, page_options)
				else
					status 404
				end
			end
		end
	  end
    end
  end
end