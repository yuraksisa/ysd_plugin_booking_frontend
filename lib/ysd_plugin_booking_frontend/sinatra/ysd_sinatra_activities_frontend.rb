module Sinatra
  module YitoExtension
    module BookingActivitiesFrontend

      def self.registered(app)

        #
        # GET /reserva-actividades/actividades
        #
        # Show the activities list
        #
        app.get '/reserva-actividades/actividades' do

          load_page(:activities)

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
          load_page(:activity)

        end
        
        #
        # GET /reserva-actividades/carrito
        #
        # Show the shopping cart
        #
        app.get '/reserva-actividades/carrito' do
          load_page(:activities_shopping_cart)          
        end
        
        #
        # GET /reserva-actividades/revisar
        #
        # Show the checkout form - before confirm the order
        #
        app.get '/reserva-actividades/revisar' do
          
          load_page(:activities_checkout)
          
        end

        #
        # GET /reserva-actividades/pedido/:free_access_id
        #
        app.get '/reserva-actividades/pedido/:free_access_id' do

          @order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:free_access_id])
          load_page(:activities_order)
          
        end

      end

    end
  end
end  