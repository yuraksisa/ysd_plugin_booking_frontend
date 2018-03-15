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
        
      locals = {}
      locals.store(:booking_min_days,
        SystemConfiguration::Variable.get_value('booking.min_days', '1').to_i)
      locals.store(:booking_item_family, 
        ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family')))
      locals.store(:booking_item_type,
        SystemConfiguration::Variable.get_value('booking.item_type')) 
      locals.store(:pickup_return_places_configuration,
        SystemConfiguration::Variable.get_value('booking.pickup_return_places_configuration', 'list'))

      young_driver_rules = SystemConfiguration::Variable.get_value('booking.driver_min_age.rules', 'false').to_bool
      young_driver_rule_definition = ::Yito::Model::Booking::BookingDriverAgeRuleDefinition.get(SystemConfiguration::Variable.get_value('booking.driver_min_age.rule_definition'))

      locals.store(:driver_age_rules, young_driver_rules)
      locals.store(:driver_age_rule_definition, young_driver_rule_definition)

      case block_name
        when 'booking_selector_full_v2'
          frontend_skin = SystemConfiguration::Variable.get_value('frontend.skin',nil)
          page = frontend_skin ? "#{frontend_skin}_rent_search_form_full_v2" : :rent_search_form_full_v2
          js = frontend_skin ? "#{frontend_skin}_rent_search_form_full_v2_js" : :rent_search_form_full_v2_js
          result = app.partial(page, :locals => locals)
          result << app.partial(js, :locals => locals)         
      end
      
    end

  end
end          