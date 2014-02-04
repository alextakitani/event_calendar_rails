require 'rails'
module EventCalendarRails

   module ViewHelpers

      def month_calendar(date = Date.today, events=nil, &block)
        Calendar.new(self, date, events, "month", nil, nil, nil, nil , display_mode=:regular, block).table
      end

      def week_calendar(date = Date.today, events=nil, start_time = Time.zone.parse("08:00"), end_time = Time.zone.parse("19:30"), interval=30.minutes, precedence=1.hour,
        display_mode=:regular, &block)
        Calendar.new(self, date, events, "week", start_time, end_time, interval, precedence, display_mode, block ).table
      end

      def week_calendar_admin(date = Date.today, events=nil, start_time = Time.zone.parse("08:00"), end_time = Time.zone.parse("19:30"), interval=30.minutes, precedence=1.hour, display_mode=:admin, &block)
        Calendar.new(self, date, events, "week", start_time, end_time, interval, precedence, display_mode, block ).table
      end

      def week_calendar_full_day(date = Date.today, events=nil , &block)
        Calendar.new(self, date, events, "week_full", nil, nil, nil, nil, :regular, block ).table
      end


      class Calendar < Struct.new(:view, :date, :events, :mode, :start_time, :end_time, :interval, :precedence, :display_mode, :callback)
        HEADER = %w[Domingo Segunda Terça Quarta Quinta Sexta Sábado]
        START_DAY = :sunday

        delegate :content_tag, to: :view

        def navigation
          prev = mode=="month" ? date.prev_month : date.prev_week
          nex  = mode=="month" ? date.next_month : date.next_week

          content_tag :div, id: "month" do
             view.link_to("<", {date: Proc.new { prev }.call}, {remote: true}) +
             content_tag(:span, I18n.localize(date,:format =>"%B %Y")) +
             view.link_to(">", {date: Proc.new { nex }.call} , {remote: true})
          end
        end

        def table
          #binding.pry
          tb = content_tag :table, class: "table table-striped table-bordered" do
            header + week_rows + time_rows + (footer if display_mode==:admin)
          end
          navigation + view.tag("br") + tb
        end

        def time_rows
          return if mode == "month"
          if mode=="week_full"
            content_tag(:tr, :class=>'full_row') do
                7.times.map do |i|
                  content_tag :td do
                      full_action_div(weeks[0][i])
                  end
                end.join.html_safe
              end
          else
            (start_time.to_i..end_time.to_i).step(interval).map do |h|
              content_tag(:tr, :class=>h) do
                8.times.map do |i|
                  content_tag :td do
                    if i == 0
                      I18n.localize(Time.zone.at(h),:format=>"%H:%M")
                    else
                      action_div(weeks[0][i-1],h,h+interval)
                    end
                  end
                end.join.html_safe
              end
            end.join.html_safe
          end
        end

        def full_action_div(date)

          unless events.nil?
            events.find_all{|e| e[0]==Time.zone.parse(date.to_s).to_i}.map do |ev|
                content_tag(:div, "", :class =>"event",
                            :data=> ev.last, :style=>"width:95%;" )
            end.join.html_safe
          end
        end

        def action_div(date,start,endt)
          cur_date = Time.zone.parse(date.to_s + " 00:00:00")
          start_time = Time.zone.parse(date.to_s + " " + Time.zone.at(start).strftime("%H:%M"))
          end_time = Time.zone.parse(date.to_s + " " + Time.zone.at(endt).strftime("%H:%M"))
          now = Time.zone.now

          ar= [cur_date.to_i,
               start_time.to_i,
               end_time.to_i]

          unless events.nil?
            if ev=events.find{|i| i[0..2]==ar}

              if display_mode ==:admin || now + precedence.seconds < start_time
                content_tag(:div, ev.last, :class =>"livre label label-success verde",
                            :data=> {
                                      :date=>ar,
                                      :day=>I18n.localize(cur_date,:format=>"%A, %d de %B de %Y"),
                                      :start_time=>start_time.strftime("%H:%M"),
                                      :end_time=>end_time.strftime("%H:%M")
                            }, :style=>"width:95%;" )
              else
                content_tag(:div, "Indisponível" , :class =>"label", :style=>"width:95%;" )
              end
            end
          end
        end

        def footer
          weeks.map do |week|
            content_tag :tr do
              content_tag(:td,'Totais',:class=>'direita') +
              week.map { |day| footer_cell(day) }.join.html_safe
            end
          end.join.html_safe

        end

        def footer_cell(day)
          content_tag(:td, events.select{|i| i[0]==Time.zone.parse(day.to_s).to_i}.map{|a| a[3].gsub("atendimento(s)","").to_i}.sum  , class: day_classes(day),:style=>"text-align:center")
        end

        def header
          HEADER.unshift("") unless mode == "week_full" || HEADER.size == 8
          content_tag :tr do
            HEADER.map { |day| content_tag :th, day,:style=>"width:12.5%" }.join.html_safe
          end
        end

        def week_rows
          weeks.map do |week|
            content_tag :tr do
              content_tag(:td,' ',:class=>'direita') +
              week.map { |day| day_cell(day) }.join.html_safe
            end
          end.join.html_safe
        end

        def day_cell(day)
          content_tag(:td, content_tag(:span,view.capture(day, &callback),:class=>"badge") , class: day_classes(day),:style=>"text-align:center")
        end

        def day_classes(day)
          classes = []
          classes << "day today" if day == Date.today
          classes << "day notmonth" if day.month != date.month
          classes.empty? ? "day" : classes.join(" ")
        end

        def weeks

          if mode == "month"
            first = date.to_date.beginning_of_month.beginning_of_week(START_DAY)
            last = date.to_date.end_of_month.end_of_week(START_DAY)
          elsif mode == "week" || mode == "week_full"
            first = date.to_date.beginning_of_week(START_DAY)
            last = date.to_date.end_of_week(START_DAY)
          end
          (first..last).to_a.in_groups_of(7)
          #(first.to_i..last.to_i).step(1.day).map{|d| Date.parse(Time.at(d).to_s) }.in_groups_of(7)
        end
      end

  end
end