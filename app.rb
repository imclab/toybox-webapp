require 'sinatra'
require 'haml'
require 'soundcloud'
require 'json'

require './lib/patched_soundcloud'
require './lib/models'

set :haml, :format => :html5
enable :sessions

helpers do

  def events
    {
      'button1' => 'Clicks Button 1',
      'button2' => 'Clicks Button 2',
      'button3' => 'Clicks Button 3',
      'microphone' => 'Speaks to the toy',
      'accelerometer' => 'Moves the toy',
      'gyro' => 'Rotates the toy'
    }
  end

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
  unless user.nil?
    user.access_token = access_token
    user.save
    return user
  end
  User.create(:id => id, :access_token => access_token, :username => username)
end

def tracks_for(device)
  content_type :json
  device.tracks.collect {|x| {:url => x.url, :event => x.event }}.to_json
end

# fetch track resource given a permalink_url
def resolve_track(track)
  client = soundcloud_client()
  begin
    track = client.get('/resolve', { :url => track }, :follow_redirects => false)
  rescue Soundcloud::ResponseError => e
    location = e.response['location']
    track = client.get(location)
  end
  track
end

get '/' do
  if current_user
    haml :index
  else
    redirect '/login'
  end
end

get '/login' do
  haml :login
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
  haml :add_device
end

post '/devices/add' do
  device = params[:device]
  Device.create(:user => current_user, :name => device['name'], :id => device['id'])
  redirect '/'
end

post '/tracks/:device' do
  device = Device.find(params[:device])
  Track.create(:device => device, :url => track[:url])
  redirect '/'
end

get '/tracks/:device.json' do
  device = Device.get(params[:device])
  pass if device.nil?
  tracks_for(device)
end

get '/tracks/:device' do
  haml :list_tracks, :locals => {:device => Device.get(params[:device])}
end

get '/tracks/:device/add' do
  haml :add_track, :locals => {:device => Device.get(params[:device])}
end

post '/tracks/:device/add' do
  device = Device.get(params[:device])
  track = params[:track]
  resource = resolve_track(track['url'])
  track_url = "#{resource.stream_url}?client_id=#{ENV['SOUNDCLOUD_CLIENT_ID']}"
  Track.create(:device => device, :event => track['event'], :url => track_url, :title => resource.title)
  redirect '/'
end
