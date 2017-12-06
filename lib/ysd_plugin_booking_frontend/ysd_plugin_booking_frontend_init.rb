require 'ysd-plugins' unless defined?Plugins::Plugin

Plugins::SinatraAppPlugin.register :booking_frontend do

   name=        'booking_frontend'
   author=      'yurak sisa'
   description= 'Booking integration'
   version=     '0.1'
   hooker       YsdPluginBookingFrontend::BookingFrontendExtension
   sinatra_extension Sinatra::YitoExtension::BookingFrontend
   sinatra_helper Sinatra::YitoExtension::BookingFrontendRESTApiHelper
   sinatra_extension Sinatra::YitoExtension::BookingFrontendRESTApi
   sinatra_extension Sinatra::YitoExtension::BookingActivitiesFrontend
   sinatra_extension Sinatra::YitoExtension::BookingActivitiesFrontendRESTApi   
end   