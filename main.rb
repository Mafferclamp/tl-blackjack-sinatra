require 'rubygems'
require 'sinatra'
require 'shotgun'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'I am not sure what this does'

get '/' do
 erb :login
end

post '/login' do
	erb :login
	session[:player_name] = params['player_name']
	redirect '/game'
end

get '/game' do
	erb :game
end


get '/profile' do
	erb :'/users/profile'
end