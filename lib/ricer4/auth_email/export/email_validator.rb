class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present?
    options = default_options.merge(self.options)
    address = ValidEmail2::Address.new(value)
    error(record, attribute, :format) && return unless address.valid?
    if options[:disposable]
      error(record, attribute, :disposable) && return if address.disposable?
    end
    if options[:blacklist]
      error(record, attribute, :blacklist) && return if address.blacklisted?
    end
    if options[:mx]
      error(record, attribute, :mx) && return unless address.valid_mx?
    end
  end
  def error(record, attribute, reason)
    reason = I18n.t!("ricer4.param.email.err_#{reason}") rescue "did not pass the email #{reason} test"
    record.errors.add(attribute, reason)
  end
end
