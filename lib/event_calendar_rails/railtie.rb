require "event_calendar_rails/view_helpers"
module EventCalendarRails
  class Railtie < Rails::Railtie

    initializer "event_calendar_rails.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end
  end
end