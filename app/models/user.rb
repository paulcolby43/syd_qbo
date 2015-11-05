class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # :database_authenticatable
  devise :registerable,:database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :timeoutable, :omniauth_providers => [:intuit]
       
  has_many :image_files
  has_many :shipment_files
  has_one :user_setting
#  has_one :qbo_access_credential
  belongs_to :company, foreign_key: "location"
  
  after_commit :create_user_settings, :on => :create
  
  #############################
  #     Instance Methods      #
  ############################
  
  def create_user_settings
    UserSetting.create(user_id: id)
  end
  
  def show_thumbnails?
    user_setting.show_thumbnails?
  end
  
  def show_vendor_thumbnails?
    user_setting.show_vendor_thumbnails?
  end
  
  def images_table?
    user_setting.table_name == "images"
  end
  
  def shipments_table?
    user_setting.table_name == "shipments"
  end
  
  def contracts
    Contract.where(company_id: location)
  end
  
  def default_contract
    contracts = Contract.where(company_id: location)
    unless contracts.empty?
      return contracts.last
    else
      nil
    end
  end
  
  def default_contract_wording
    contracts = Contract.where(company_id: location)
    unless contracts.empty?
      return contracts.last.wording
    else
      nil
    end
  end
  
  def devices
    Device.where(CompanyID: location)
  end
  
  def scale_devices
    Device.where(CompanyID: location, DeviceType: 21)
  end
  
  def camera_devices
    Device.where(CompanyID: location, DeviceType: 5)
  end
  
  def qbo_access_credential
    QboAccessCredential.find_by_company_id(location)
  end
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.find_for_open_id(access_token, signed_in_resource=nil)
    data = access_token.info
    if user = User.where(:email => data["email"]).first
      user
    else
      User.create!(:email => data["email"], :password => Devise.friendly_token[0,20])
    end
  end
  
end
