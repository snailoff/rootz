require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'rouge'
require 'logger'
require 'pathname'

require './rootz'

configure do
end

get '/root/*' do |path|	
	@rz

	begin
		@rz = Rootz::Root.new path
		@rz.check
		@rz.read
		@rz.parse
		
	rescue Rootz::InvalidPathError => e
		logger.error e.message
		logger.error "redirect => #{e.object[:redirect_url]}"
		redirect to e.object[:redirect_url]
	end

	haml :index
	
end

get '*' do
  redirect to('/root/')
end



