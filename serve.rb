require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'rouge'
require 'logger'
require 'pathname'

require './rootz'
require './version'

configure do
	enable :reloader
end

get '/root/*' do |path|	
	@rz

	begin
		@rz = Rootz::Root.new path
		@rz.check
		@rz.read
		@rz.recent
		@rz.parse
		
	rescue Rootz::InvalidPathError => e
		logger.error e.message
		logger.error "redirect => #{e.object[:redirect_url]}"
		redirect to e.object[:redirect_url]
	end

	haml :index
	
end

get '/' do
  redirect to('/root/')
end

get '/root' do
  redirect to('/root/')
end



