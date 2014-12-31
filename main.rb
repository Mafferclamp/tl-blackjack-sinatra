require 'rubygems'
require 'sinatra'
require 'shotgun'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'I am not sure what this does'


get '/' do
	if session[:player_name]
		redirect '/game'
	else
 		redirect '/login'
 	end
end

get '/login' do 
	erb :login
end

post '/login' do
	session[:player_name] = params['player_name']
	session[:buy_in] = params['buy_in']
	redirect '/bet'
end

get '/game' do
	ranking = %w(2 3 4 5 6 7 8 9 10 J Q K)
	suits = %w(♦ ♣ ♥ ♠)
	deck = suits.product(ranking).shuffle!

	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	erb :game
end


get '/profile' do
	erb :'/users/profile'
end

get '/bet' do 
	erb :bet
end

post '/bet' do 
	session[:bet] = params['bet']
	redirect '/game'
end