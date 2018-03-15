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
                    custom_pickup_place: shopping_cart.custom_pickup_place,
                    return_place: shopping_cart.return_place,
                    return_place_customer_translation: shopping_cart.return_place_customer_translation,
                    custom_return_place: shopping_cart.custom_return_place
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
                            date_from: booking.date_from.strftime('%Y-%m-%d'),
                            date_to: booking.date_to.strftime('%Y-%m-%d'),
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
                                 custom_pickup_place: booking.custom_pickup_place,
                                 return_place: booking.return_place,
                                 return_place_customer_translation: booking.return_place_customer_translation,
                                 custom_return_place: booking.custom_return_place
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
          can_pay = SystemConfiguration::Variable.get_value('booking.payment','false').to_bool &&
              BookingDataSystem::Booking.payment_cadence?(shopping_cart.date_from, shopping_cart.time_from)
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
  end
end