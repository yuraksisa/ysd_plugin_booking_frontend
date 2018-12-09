#
# Booking Front-end Extension
#
module YsdPluginBookingFrontend

  class BookingFrontendExtension < Plugins::ViewListener


    # ========= Installation =================

    # 
    # Install the plugin
    #
    def install(context={})

      SystemConfiguration::Variable.first_or_create(
          {:name => 'booking.frontend.activities_menu'},
          {:value => 'false',
           :description => 'Activities have their own menus',
           :module => :booking})

      SystemConfiguration::Variable.first_or_create(
          {name: 'booking.frontend.confirmation_step_2'},
          {value: 'false',
           description: 'Allows to define a step to confirm a reservation. Only in case you want to ',
           module: :booking_frontend}
      )

      Site::Menu.first_or_create({:name => 'primary_links_activities'},
                                 {:title => 'Primary links activities menus',
                                           :description => 'Primary links activities menu'})

      Site::Menu.first_or_create({:name => 'secondary_links_activities'},
                                 {:title => 'Secondary links activities menu',
                                           :description => 'Secondary links activities menu'})


    end
    
    # ----------- Blocks ------------------------------------

    # Retrieve all the blocks defined in this module 
    # 
    # @param [Hash] context
    #   The context
    #
    # @return [Array]
    #   The blocks defined in the module
    #
    #   An array of Hash which the following keys:
    #
    #     :name         The name of the block
    #     :module_name  The name of the module which defines the block
    #     :theme        The theme
    #
    def block_list(context={})
    
      app = context[:app]
    
      [
       {:name => 'booking_selector_full_v2',
        :module_name => :booking_frontend,
        :theme => Themes::ThemeManager.instance.selected_theme.name},
       {:name => 'booking_activities_shopping_cart',
        :module_name => :booking_frontend,
        :theme => Themes::ThemeManager.instance.selected_theme.name}
      ]
        
    end

    # Get a block representation
    #
    # @param [Hash] context
    #   The context
    #
    # @param [String] block_name
    #   The name of the block
    #
    # @return [String]
    #   The representation of the block
    #    
    def block_view(context, block_name)

      app = context[:app]

      case block_name
        when 'booking_activities_shopping_cart'
          shopping_cart = ::Yito::Model::Order::ShoppingCart.get(app.session[:shopping_cart_id]) || ::Yito::Model::Order::ShoppingCart.new
          app.partial(:activities_shopping_cart, :locals => {shopping_cart: shopping_cart})

        when 'booking_selector_full_v2'
          booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          young_driver_rules = SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool
          young_driver_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))
          addons = app.mybooking_addons
          addon_promotion_code = if addons and addons.has_key?(:addon_promotion_code) and addons[:addon_promotion_code]
                                   addons[:addon_promotion_code]
                                 else
                                   false
                                 end
          locals = {}
          locals.store(:booking_min_days,
                       SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
          locals.store(:booking_item_family, booking_item_family)
          locals.store(:booking_item_type,
                       SystemConfiguration::Variable.get_value('booking.item_type'))
          locals.store(:pickup_return_places_configuration,
                       SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))
          locals.store(:driver_age_rules, young_driver_rules)
          locals.store(:driver_age_rule_definition, young_driver_rule_definition)
          locals.store(:addon_promotion_code, addon_promotion_code)
          locals.store(:custom_pickup_return_place_price, SystemConfiguration::Variable.get_value('booking.custom_pickup_return_place_price', '0').to_i)
          locals.store(:pickup_return_places_same_rental_location, BookingDataSystem::Booking.pickup_return_places_same_rental_location)

          frontend_skin = SystemConfiguration::Variable.get_value('frontend.skin','rentit')
          custom_js = Plugins::Plugin.plugin_invoke_all('frontend_skin_custom_js', context).inject(false) { |result, value| result = result or value }

          page = frontend_skin ? "#{frontend_skin}_rent_search_form_full_v2" : :rent_search_form_full_v2
          js = (frontend_skin and custom_js) ? "#{frontend_skin}_rent_search_form_full_v2_js" : :rent_search_form_full_v2_js

          if booking_item_family.driver and young_driver_rules and young_driver_rule_definition and !young_driver_rule_definition.driver_age_rules.empty?
            driver_partial = frontend_skin ? "#{frontend_skin}_rent_search_form_full_v2_driver" : :rent_search_form_full_v2_driver
            locals.store(:driver_partial, app.partial(driver_partial, locals: locals))
          else
            locals.store(:driver_partial, nil)
          end

          if addon_promotion_code
            promotion_code_partial = frontend_skin ? "#{frontend_skin}_rent_search_form_full_v2_promotion_code" : :rent_search_form_full_v2_promotion_code
            locals.store(:promotion_code_partial, app.partial(promotion_code_partial, locals: locals))
          else
            locals.store(:promotion_code_partial, nil)
          end

          result = app.partial(page, :locals => locals)
          result << app.partial(js, :locals => locals)         
      end
      
    end

  end
end          