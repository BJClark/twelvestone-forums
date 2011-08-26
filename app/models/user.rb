class User
  include MongoMapper::Document
  include MongoMapper::Sluggable
  include MongoMapper::EmbeddableDocument
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  key :email,  String, :required => true, :index => true
  key :name,  String,  :required => true, :index => true
  key :post_count, Integer, :default => 0
  key :encrypted_password, String
  key :password_salt, String
  key :reset_password_token, String
  key :remember_token, String
  key :remember_created_at, Time
  key :sign_in_count, Integer
  key :current_sign_in_at, Time
  key :current_sign_in_ip, String  
  key :role, String, :default => "member"

  validates_format_of :email, :with => /.+@.+\..+/
  validates_uniqueness_of :name, :with => "has already been taken"
  
  timestamps!
  embedded_attributes :email, :name, :slug, :post_count
  
  def admin?
    "admin" == role
  end
end
