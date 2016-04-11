module Ricer4::Plugins::Auth
  class EmailConfirmation < ActiveRecord::Base
    
    PIN_LENGTH ||= 16
    
    # Types
    SETUP_CONFIRM ||= 1
    CHANGE_REQUEST ||= 2
    CHANGE_CONFIRM ||= 3
    RECOVERY_CONFIRM ||= 4
    
    # Relations
    belongs_to :user, class_name: 'Ricer4::User'
    scope :not_expired, -> { where('expires > ?', Time.now) }

    # Validators    
    validates :user, presence: true
    validates :email, email: { mx: true, disposable: true, blacklist: true }
    validates :confirmtype, numericality: { only_integer: true, larger_than: 0, less_than: 5 } 

    # Cleanup once in a while    
    after_commit -> { self.class.all.where("expires < ?", Time.now).delete_all }

    # Table layout in ricer plugin style
    arm_install('Ricer4::User' => 1) do |m|
      m.create_table table_name do |t|
        t.integer   :user_id,     :null => false
        t.integer   :confirmtype, :null => false, :length => 1,  :unsigned => true
        t.string    :email,       :null => true
        t.string    :code,        :null => false, :length => PIN_LENGTH, :charset => :ascii, :collate => :ascii_bin
        t.timestamp :expires,     :null => false
        t.timestamp :created_at,  :null => false
      end
    end
    
  end
end
