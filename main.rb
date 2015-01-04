require 'rubygems'
require 'sinatra'
require 'shotgun'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'I am not sure what this does'

helpers do 
	def calculate_total(cards)
		#isolate the rankings of the cards from the suits
		value = cards.map {|e| e[1] }

		total = 0 
		value.each do |card|
			if card == "A"
				total += 11
			elsif card.to_i == 0
				total += 10
			else
				total += card.to_i
			end
		end

		value.select{|card| card == 'A'}.count.times do 
			total -= 10 if total > 21
		end
		total 
	end

	def card_image(card)
		suit = case card[0]
			when 'D' then 'diamonds'
			when 'C' then 'clubs'
			when 'H' then 'hearts'
			when 'S' then 'spades'
		end

		value = card[1]
		if %w[J Q K A].include?(value)
			value = case card[1] 
				when 'J' then 'jack'
				when 'Q' then 'queen'
				when 'K' then 'king'
				when 'A' then 'ace'
			end
		end

		"<img src='/images/cards/#{suit}_#{value}.jpg' alt='the #{value} of #{suit}' class='card_image'> "
	end

	def calculate_winner(dealer_total, player_total)
		if dealer_total > player_total
			@error = "Dealer has #{dealer_total}, you have #{player_total} sorry #{session[:player_name]} loses"
		elsif player_total > dealer_total
			@success =  "Dealer has #{dealer_total}, you have #{player_total} Congratualtions #{session[:player_name]} win"
		end
	end
end

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
	if params[:player_name].empty?
		@error = "You must enter a name"
		halt erb(:login)
	elsif params[:buy_in].empty?
		@error = "You must buy in to enter the game"
		halt erb(:login)
	end
	session[:player_name] = params['player_name']
	session[:buy_in] = params['buy_in']
	redirect '/bet'
end

get '/game' do
	ranking = %w(2 3 4 5 6 7 8 9 10 J Q K A)
	suits = %w(D C H S)
	session[:deck] = suits.product(ranking).shuffle!
	@dealer_turn = false

	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop


	erb :game
end

before do 
	@show_hit_stay = true 
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop

	player_total = calculate_total(session[:player_cards])
	if player_total == 21
		@success = "Congratulations #{session[:player_name]} hit Blackjack!"
		@show_hit_stay = false
	elsif player_total > 21
		@error = "Sorry #{session[:player_name]}, you're busted"
		@show_hit_stay = false
		@play_again = true
	end
	erb :game
end

post '/game/player/stay' do 
	@success = "#{session[:player_name]} has chosen to stay."
	@show_hit_stay = false
	@dealer_turn = true
	erb :game 
end

post '/game/dealer/hit' do 
	
	session[:dealer_cards] << session[:deck].pop
	@show_hit_stay = false

	dealer_total = calculate_total(session[:dealer_cards])
	player_total = calculate_total(session[:player_cards])

	if dealer_total < 16
		@dealer_turn = true
	elsif dealer_total >21
		@success = "Dealer busted! #{session[:player_name]} wins!"
		@play_again = true
	elsif dealer_total >= 16
		calculate_winner(dealer_total, player_total)
		@play_again = true
	end

	erb :game
end

get '/bet' do 
	erb :bet
end

post '/bet' do 
	session[:bet] = params['bet']
	erb :bet
	redirect '/game'
end