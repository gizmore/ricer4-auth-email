module Ricer4::Plugins::Auth
  class EmailChange < Ricer4::Plugin
  
    trigger_is :change_email
    permission_is :registered
    
    has_setting name: :valid_for, type: :duration, scope: :bot, permission: :responsible, default: 4.hours, max: 1.month, integer: true
    
    has_usage "<email> <pin|length:#{EmailConfirmation::PIN_LENGTH}>", function: :execute_confirm
    has_usage '<email>', function: :execute_request
    
    def execute_request(email)
      # May not change that easily!
      return erplyp(:err_mail_not_set) if sender.email.nil?
      pin = ActiveRecord::Magic::Param::Pin.random_pin(EmailConfirmation::PIN_LENGTH)
      # Create one for user
      confirmation = EmailConfirmation.create!(
        user: sender,
        confirmtype: EmailConfirmation::CHANGE_REQUEST,
        code: pin.value,
        email: email.address.to_s,
        expires: valid_until
      )
      # Send mail
      send_request_mail(confirmation, pin)
      # And tell him
      nrplyp :msg_sent, email: email.address.to_s, duration: show_setting(:valid_for)
    end
    
    def execute_confirm(email, pin)
      return erplyp(:err_mail_not_set) if sender.email.nil?
      confirmation = EmailConfirmation.not_expired.where(user:user, email:email.address.to_s, code:pin.value).first
      return erply :err_code if confirmation.nil?
      EmailConfirmation.delete_all(:user_id => user.id)
      if confirmation.confirmtype == EmailConfirmation::CHANGE_REQUEST
        execute_confirm_request(email)
      elsif confirmation.confirmtype == EmailConfirmation::CHANGE_CONFIRM
        execute_confirm_change(email)
      end
    end
    
    protected
    
    def execute_confirm_request(email)
      pin = ActiveRecord::Magic::Param::Pin.random_pin(EmailConfirmation::PIN_LENGTH)
      # Create one for user
      confirmation = EmailConfirmation.create!(
        user: sender,
        confirmtype: EmailConfirmation::CHANGE_CONFIRM,
        code: pin.value,
        email: email.address.to_s,
        expires: valid_until
      )
      # Send mail
      send_request_mail(confirmation, pin)
      # And tell him
      nrplyp :msg_sent, email: email.address.to_s, duration: show_setting(:valid_for)
    end

    def execute_confirm_change(email)
      sender.email = email
      sender.save!
      return rplyp :msg_set, email:user.email
    end

    private
    
    def valid_until
      Time.now + get_setting(:valid_for)
    end
    
    def send_request_mail(confirmation, pin)
      subj = t(:mail_request_subj)
      body = t(:mail_request_body, user:sender.name, code:pin.display, newmail:confirmation.email)
      send_mail(sender.email, subj, body)
    end
    
    def send_change_mail(confirmation, pin)
      to = confirmation.email
      subj = t(:mail_confirm_subj)
      body = t(:mail_confirm_body, user:sender.name, code:pin.display, newmail:to)
      send_mail(to, subj, body)
    end
    
  end
end
