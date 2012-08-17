require 'sinatra'
require 'haml'
require 'soundcloud'

require './lib/patched_soundcloud'

set :haml, :format => :html5

get '/' do
  haml :index
end
