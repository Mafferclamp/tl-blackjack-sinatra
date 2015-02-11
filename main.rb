require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'I am not sure what this does'

BLACKJACK = 21
DEALER_MIN_HIT = 16


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
			total -= 10 if total > BLACKJACK
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

	def blank_card
		"<img src='/images/cards/cover.jpg' alt='the #{value} of #{suit}' class='card_image'> "
	end

	def winner!(msg)
		@winner= "<strong>#{session[:player_name]} wins!</strong> #{msg}"
		session[:buy_in] = session[:buy_in] + session[:bet]
	end

	def loser!(msg)
		@loser = "<strong>#{session[:player_name]} loses!</strong> #{msg}"
		session[:buy_in] = session[:buy_in] - session[:bet]
	end

	def tie!(msg)
		@play_again = true
		@tie = "<strong>It's a tie</strong> #{msg}"

	end

	def calculate_winner(dealer_total, player_total)
		if dealer_total > player_total
			loser!("Dealer has #{dealer_total}, you have #{player_total} sorry #{session[:player_name]} loses")
		elsif player_total > dealer_total
			winner!("Dealer has #{dealer_total}, you have #{player_total} Congratualtions #{session[:player_name]} win")
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
	session[:player_name] = nil
	session[:buy_in] = nil 
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
	session[:buy_in] = params['buy_in'].to_i
	redirect '/bet'
end

get '/game' do
	ranking = %w(2 3 4 5 6 7 8 9 10 J Q K A)
	suits = %w(D C H S)
	session[:deck] = suits.product(ranking).shuffle!
	@dealer_turn = false
	session[:turn] = session[:player_name]

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
	session[:turn] = 'player'

	player_total = calculate_total(session[:player_cards])
	if player_total == BLACKJACK
		winner!("Congratulations #{session[:player_name]} hit Blackjack!")
		@show_hit_stay = false
		@play_again = true
	elsif player_total > BLACKJACK
		loser!("Sorry #{session[:player_name]}, you're busted")
		@show_hit_stay = false
		@play_again = true
	end
	erb :game, layout: false
end

post '/game/player/stay' do 
	session[:turn] = 'dealer'
	@success = "#{session[:player_name]} has chosen to stay."
	@show_hit_stay = false
	@dealer_turn = true
	erb :game 
end

post '/game/dealer/hit' do 
		session[:turn] = 'dealer'
	session[:dealer_cards] << session[:deck].pop
	@show_hit_stay = false

	dealer_total = calculate_total(session[:dealer_cards])
	player_total = calculate_total(session[:player_cards])

	if dealer_total < DEALER_MIN_HIT
		@dealer_turn = true
	elsif dealer_total >BLACKJACK
		winner!("Dealer busted!")
		@play_again = true
	elsif dealer_total >= DEALER_MIN_HIT
		calculate_winner(dealer_total, player_total)
		@play_again = true
	end

	erb :game, layout: false
end

get '/bet' do 
	session[:bet] = nil
	erb :bet
end

post '/bet' do 
	if params[:bet].nil? || params[:bet].to_i == 0
		@error = "You must bet to continue"
	 	halt erb (:bet)
	elsif params[:bet].to_i > session[:buy_in].to_i 
		@error = "You can not bet more than you have ($#{session[:buy_in]})"
	 	halt erb (:bet)
	else
		session[:bet] = params[:bet].to_i
		redirect '/game'
	end

	# erb :bet

end

get '/gameover' do
	erb :gameover
end