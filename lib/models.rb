require 'dm-core'
require 'dm-migrations'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  has n, :devices

  property :id,           Integer, :required => true, :key => true
  property :username,     String,  :required => true
  property :access_token, String,  :required => true
end

class Track
  include DataMapper::Resource

  belongs_to :device

  property :id,    Serial
  property :event, String, :required => true
  property :url,   String, :length => 100
end

class Device
  include DataMapper::Resource

  belongs_to :user
  has n, :tracks

  property :id,   String, :required => true, :key => true
  property :name, String, :required => true
end

DataMapper.finalize
DataMapper.auto_upgrade!
