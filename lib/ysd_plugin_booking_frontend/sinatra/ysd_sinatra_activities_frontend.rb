module Sinatra
  module YitoExtension
    module BookingActivitiesFrontend

      def self.registered(app)

        app.set :ordercharge_gateway_return_ok, '/reserva-actividades/payment-gateway-return/ok'
        app.set :ordercharge_gateway_return_cancel, '/reserva-actividades/payment-gateway-return/cancel'
        app.set :ordercharge_gateway_return_nok, '/reserva-actividades/payment-gateway-return/nok'

        #
        # GET /reserva-actividades/actividades
        #
        # Show the activities list
        #
        app.route :get, ['/reserva-actividades/actividades','/excursiones'] do

          locals = {}

          # Load the page
          title = t.front_end_activities.activities_title

          page = settings.frontend_skin ? "#{settings.frontend_skin}_activities" : :activities
          page_options = {page_title: title, locals: locals, cache: false}

          default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
          page_options.store(:custom_js, 'activities') unless default_js

          load_page(page, page_options)
        end
        
        #
        # GET /reserva-actividades/calendario
        #
        # Show the activities in a calendar
        #
        app.get '/reserva-actividades/calendario' do
          
        end
        
        #
        # GET /reserva-actividades/actividades/:id
        #
        # Show an activity detail
        #
        app.get '/reserva-actividades/actividades/:id' do

          @activity_id = params[:id]
          locals = {}

          # Load the page
          title = nil

          page = settings.frontend_skin ? "#{settings.frontend_skin}_activity" : :activity
          page_options = {page_title: title, locals: locals, cache: false}

          default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
          page_options.store(:custom_js, 'activity') unless default_js

          load_page(page, page_options)
        end

        #
        # Load an activity (by its alias)
        #
        app.get /^[^.]*$/ do

          preffixes = Plugins::Plugin.plugin_invoke_all('ignore_path_prefix_cms', {:app => self})
          if request.path_info.empty? or request.path_info.start_with?(*preffixes)
            pass
          end

          # Query activity
          if @activity = ::Yito::Model::Booking::Activity.first(:alias => request.path_info)
            @activity_id = @activity.id

            locals = {}
            # Load the page
            title = nil

            page = settings.frontend_skin ? "#{settings.frontend_skin}_activity" : :activity
            page_options = {page_title: title, locals: locals, cache: false}

            default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
            page_options.store(:custom_js, 'activity') unless default_js

            load_page(page, page_options)
          else
            pass
          end

        end

        #
        # GET /reserva-actividades/carrito
        #
        # Show the shopping cart
        #
        app.route :get, ['/reserva-actividades/carrito', '/shopping-cart'] do

          @payment_methods = Payments::PaymentMethod.available_to_web
          @deposit = SystemConfiguration::Variable.get_value('order.deposit', '0').to_i
          @currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')

          locals = {}
          # Load the page
          title = nil

          page = settings.frontend_skin ? "#{settings.frontend_skin}_activities_shopping_cart" : :activities_shopping_cart
          page_options = {page_title: title, locals: locals, cache: false}

          default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
          page_options.store(:custom_js, 'activities_shopping_cart') unless default_js

          load_page(page, page_options)

        end


        #
        # Payment
        #
        # It receives three arguments in POST form
        #
        # id: The order free access id
        # payment: deposit, total or pending
        # payment_method_id: The payment method identifier
        #
        ['/reserva-actividades/pagar'].each do |endpoint|
          app.post endpoint do #, :allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do

            if order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:id])
              payment = params[:payment]
              payment_method = params[:payment_method_id]
              if charge = order.create_online_charge!(payment, payment_method)
                session[:order_id] = order.id
                session[:charge_id] = charge.id
                status, header, body = call! env.merge("PATH_INFO" => "/charge",
                                                       "REQUEST_METHOD" => 'GET')
              else
                logger.error "Activities payment - charge not created"
                status 404
              end
            else
              logger.error "Activities payment - order #{params[:id]} not found"
              status 404
            end

          end

        end

        #
        # GET /reserva-actividades/pedido/:free_access_id
        #
        app.get '/reserva-actividades/pedido/:free_access_id' do

          @order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:free_access_id])

          @payment_methods = Payments::PaymentMethod.available_to_web
          @deposit = SystemConfiguration::Variable.get_value('order.deposit', '0').to_i
          @currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
          @payment = if @order.can_pay_deposit?
                       'deposit'
                     elsif @order.can_pay_pending?
                       'pending'
                     elsif @order.can_pay_total?
                       'total'
                     else
                       ''
                     end
          
          locals = {}
          # Load the page
          title = t.front_end_activities.order_page.page_title(@order.id)

          page = settings.frontend_skin ? "#{settings.frontend_skin}_activities_order" : :activities_order
          page_options = {page_title: title, locals: locals, cache: false}

          default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
          page_options.store(:custom_js, 'activities_order') unless default_js

          load_page(page, page_options)

        end

        # =============== RETURN FROM PAYMENT GATEWAY ===================================

        #
        # Return OK from payment gateway
        #
        ['/reserva-actividades/payment-gateway-return/ok'].each do |endpoint|
          app.get endpoint do

            if session.has_key?(:charge_id)
              @order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
              @payment_methods = Payments::PaymentMethod.available_to_web
              @deposit = SystemConfiguration::Variable.get_value('order.deposit', '0').to_i
              @currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              @payment = if @order.can_pay_deposit?
                           'deposit'
                         elsif @order.can_pay_pending?
                           'pending'
                         elsif @order.can_pay_total?
                           'total'
                         else
                           ''
                         end
              
              locals = {}
              # Load the page
              title = t.front_end_activities.order_page.page_title(@order.id)

              page = settings.frontend_skin ? "#{settings.frontend_skin}_activities_order" : :activities_order
              page_options = {page_title: title, locals: locals, cache: false}

              default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
              page_options.store(:custom_js, 'activities_order') unless default_js

              load_page(page, page_options)
            else
              logger.error "Back from payment gateway - OK - NOT charge in session"
              status 404
            end

          end
        end

        #
        # Return CANCEL from payment gateway
        #
        ['/reserva-actividades/payment-gateway-return/cancel'].each do |endpoint|
          app.get endpoint do
            if session.has_key?(:charge_id)
              @order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
              @payment_methods = Payments::PaymentMethod.available_to_web
              @deposit = SystemConfiguration::Variable.get_value('order.deposit', '0').to_i
              @currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              @payment = if @order.can_pay_deposit?
                           'deposit'
                         elsif @order.can_pay_pending?
                           'pending'
                         elsif @order.can_pay_total?
                           'total'
                         else
                           ''
                         end
              
              locals = {}
              # Load the page
              title = t.front_end_activities.order_page.page_title(@order.id)

              page = settings.frontend_skin ? "#{settings.frontend_skin}_activities_order" : :activities_order
              page_options = {page_title: title, locals: locals, cache: false}

              default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
              page_options.store(:custom_js, 'activities_order') unless default_js

              load_page(page, page_options)
            else
              logger.error "Back from payment gateway - CANCEL - NOT charge in session"
              status 404
            end
          end
        end

        #
        # Return NOK from payment gateway
        #
        ['/reserva-actividades/payment-gateway-return/nok'].each do |endpoint|
          app.get endpoint do
            if session.has_key?(:charge_id)
              @order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
              @payment_methods = Payments::PaymentMethod.available_to_web
              @deposit = SystemConfiguration::Variable.get_value('order.deposit', '0').to_i
              @currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              @payment = if @order.can_pay_deposit?
                           'deposit'
                         elsif @order.can_pay_pending?
                           'pending'
                         elsif @order.can_pay_total?
                           'total'
                         else
                           ''
                         end
              
              locals = {}
              # Load the page
              title = t.front_end_activities.order_page.page_title(@order.id)

              page = settings.frontend_skin ? "#{settings.frontend_skin}_activities_order" : :activities_order
              page_options = {page_title: title, locals: locals, cache: false}

              default_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', {app: self}).inject(false) { |result, value| result = result or value }
              page_options.store(:custom_js, 'activities_order') unless default_js

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