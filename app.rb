require 'sinatra'
require 'haml'
require 'soundcloud'
require 'json'

require './lib/patched_soundcloud'
require './lib/models'

set :haml, :format => :html5
enable :sessions

helpers do
  def current_user
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end

  def soundcloud_client
    if current_user
      Soundcloud.new(:access_token => current_user.access_token)
    else
      Soundcloud.new(:client_id => ENV['SOUNDCLOUD_CLIENT_ID'],
                     :client_secret => ENV['SOUNDCLOUD_CLIENT_SECRET'],
                     :redirect_uri => ENV['SOUNDCLOUD_REDIRECT_URI'])
    end
  end
end

def soundcloud_user(id, access_token, username)
  user = User.get(id)
  return user unless user.nil?
  User.create(:id => id, :access_token => access_token, :username => username)
end

def tracks_for(device)
  content_type :json
  device.tracks.collect {|x| {:url => x.url, :event => x.event }}.to_json
end

get '/' do
  if current_user
    haml :index
  else
    redirect '/login'
  end
end

get '/login' do
  haml :login, :locals => {:authorize_url => soundcloud_client.authorize_url()}
end

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end

get '/callback' do
  client = soundcloud_client()
  token = client.exchange_token(:code => params[:code])

  me = client.get('/me')
  user = soundcloud_user(me.id, token.access_token, me.username)
  session[:user_id] = user.id

  redirect '/'
end

get '/devices/add' do
  'Yup, not implemented yet'
end

get '/tracks/:device' do
  device = Device.get(params[:device])
  pass if device.nil?
  tracks_for(device)
end
