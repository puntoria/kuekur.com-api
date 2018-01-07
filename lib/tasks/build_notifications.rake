unless Rails.env.development? || Rails.env.test?
  require 'rufus-scheduler'

  class SMSNotifier
    def initialize(receiver, event)
      @receiver = receiver
      @event = EventDecorator.new(event)
    end

    def send_message
      body = "Join us at our new nest on #{event.formatted_date("%a, %d %b")} from #{event.formatted_time} onwards at #{event.formatted_location}. - #{event.formatted_organizer}."

      client.messages.create(from: from, to: receiver.phone_number, body: body)
    end

    private

    attr_reader :receiver, :event

    def client
      @client ||= Twilio::REST::Client.new(
        "ACa5eac09ec84d0ab8565e4d1af98e724a",
        "1480787fefaa9f2c015725b0355a1b7c",
      )
    end

    def from
      "+16178588544"
    end
  end

  class EmailNotifier
    include SendGrid

    attr_reader :receiver, :event

    def initialize(receiver, event)
      @receiver = receiver
      @event = EventDecorator.new(event)
    end

    def send_email
      body = "Join us at our new nest on #{event.formatted_date("%a, %d %b")} from #{event.formatted_time} onwards at #{event.formatted_location}. - #{event.formatted_organizer}."

      to = Email.new(email: receiver.email)
      content = Content.new(type: 'text/plain', value: body)
      mail = Mail.new(from, event.formatted_organizer, to, content)

      sendgrid.client.mail._('send').post(request_body: mail.to_json)
    end

    private

    def sendgrid
      @client ||= SendGrid::API.new(
        api_key: "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"
      )
    end

    def from
      Email.new(email: 'korabhhh@gmail.com')
    end
  end

  namespace :schedulable do
    desc "Updates the ruby-advisory-db and runs audit"
    task build_notifications: :environment do
      events = Event.listed.map(&:schedule)
      all_occurrence = []
      events.map { |event|
        if event.occurs_on?(Date.today)
          all_occurrence.push(event)
        end
      }
      if all_occurrence.present?
        all_occurrence.each do |occurrence|
          event = Event.find(occurrence.schedulable_id)
          return if event.nil?

          d = EventDecorator.new(event)
          remaining_event_date = "#{d.formatted_date("%Y/%m/%d")} #{(event.schedule.time - 3.hours).strftime("%T")}"
          attendees = event.attendees
          attendees.each do |attendee|
            begin
              receiver = attendee
              job_id = scheduler.at remaining_event_date do
                notification_sending_rule = receiver.notification_sending_rule.to_sym
                if notification_sending_rule == :sms
                  send_notification_sms(receiver, event)
                elsif notification_sending_rule == :email
                  send_notification_email(receiver, event)
                end
              end
              scheduler.job(job_id)
            rescue Rufus::Scheduler::TimeoutError => exception
              Rails.logger.error "Msg: #{exception.message}"
              scheduler.at_jobs.each(&:unschedule)
              scheduler.shutdown(:kill)
            end
          end
          scheduler.join
        end
      end
    end
  end

  def scheduler
    @scheduler ||= Rufus::Scheduler.new
  end

  def send_notification_sms(receiver, event)
    SMSNotifier.new(receiver, event).send_message
  end

  def send_notification_email(receiver, event)
    EmailNotifier.new(receiver, event).send_email
  end

end
