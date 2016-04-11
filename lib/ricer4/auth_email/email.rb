module Ricer4::Plugins::Auth
  class Email < Ricer4::Plugin
  
    trigger_is :email
    permission_is :authenticated
    
    has_setting name: :valid_for, type: :duration, scope: :bot, permission: :responsible, default: 4.hours, max: 1.month, integer: true
    
    has_usage "<email> <pin|length:#{EmailConfirmation::PIN_LENGTH}>", function: :execute_confirm
    has_usage '<email>', function: :execute_request
    has_usage '', function: :execute_show
    
    def execute_show
      return rply :msg_none if user.email.nil?
      rply :msg_show, email:user.email
    end
    
    def execute_request(email)
      # May not change that easily!
      return erplyp(:err_mail_already_set) unless sender.email.nil?
      pin = ActiveRecord::Magic::Param::Pin.random_pin(EmailConfirmation::PIN_LENGTH)
      # Create one for user
      confirmation = EmailConfirmation.create!(
        user: sender,
        confirmtype: EmailConfirmation::SETUP_CONFIRM,
        code: pin.value,
        email: email.address.to_s,
        expires: valid_until
      )
      # Send mail
      send_confirmation_mail(confirmation, pin)
      # And tell him
      nrplyp :msg_sent, email: email.address.to_s, duration: show_setting(:valid_for)
    end
    
    def execute_confirm(email, pin)
      return erplyp(:err_mail_already_set) unless sender.email.nil?
      confirmation = EmailConfirmation.not_expired.where(user:user, email:email.address.to_s, code:pin.value, confirmtype:EmailConfirmation::SETUP_CONFIRM).first
      return erplyp(:err_code) if confirmation.nil?
      user.email = confirmation.email
      user.save!
      confirmation.delete
      return rplyp :msg_set, email:user.email
    end
    
    private
    
    def valid_until
      Time.now + get_setting(:valid_for)
    end
    
    def send_confirmation_mail(confirmation, pin)
      to = confirmation.email
      subj = t(:mail_subj)
      body = t(:mail_body, user:sender.name, code:pin.display, email:to)
      send_mail(to, subj, body)
    end
    
  end
end
