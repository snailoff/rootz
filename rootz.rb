module Rootz

	PREFIX_PATH = File.expand_path "../public", __FILE__
	PREFIX_PATHNAME = Pathname.new Rootz::PREFIX_PATH
	
	class InvalidPathError < StandardError
		attr_reader :object

		def initialize object
			@object = object
		end
	end

	class Root
		attr_accessor :subject, :navi, :parsed, :created, :redirect_url, :header_image

		def initialize path
			Rootz.logger.info
			@input_url = "/root/#{path}" 
			@input_path = path
			@target_path = "#{File.expand_path "../public/root", __FILE__}/#{@input_path}"
			@default_file_path = ''
			@header_image = ''

			Rootz.logger.info "@input_path : #{@input_path}"
		end

		def check
			Rootz.logger.info
			Rootz.logger.info "target full path : #{@target_path}"

			unless File.exist? @target_path
				if File.exist? "#{@target_path}.txt"
					@target_path = "#{@target_path}.txt"
				else
					@input_url = File.expand_path "..", @input_url
					@target_path = File.expand_path "..", @target_path
					check
					return
				end
			end

			@is_file = File.file? @target_path
			if !@is_file && !(@target_path =~ /\/$/)
				raise Rootz::InvalidPathError.new({:redirect_url => "#{@input_url}/"}), "redirect dir"
			end

			if !@is_file 
				target = "#{@target_path}_#{File.basename @target_path}"
				@default_file_path = target if File.exist? target
			end

			@navi = convert_navi last_dir(@target_path)
			@subject = @is_file ? basename(@target_path) : ""

			Rootz.logger.info "@subject : #{@subject}"
			Rootz.logger.info "@default_file_path : #{@default_file_path}"
			Rootz.logger.info "@header_image : #{@header_image}"
		end

		def read
			Rootz.logger.info
			Rootz.logger.info "read @target_path : #{@target_path}"


		end

		def recent
			#return if @input_path 
			
			

		end

		def parse
			Rootz.logger.info
			@parsed = ''			

			if @input_path.empty?
				Rootz.logger.info "*** root. recent pages."
				list = Dir.glob("#{File.expand_path "../public/root", __FILE__}/**/*.txt").sort_by{ |f| File.mtime(f) }.reverse
				Rootz.logger.debug "===> #{list}"

				list[0, 10].each do |f|
					@parsed += render(f)
					@parsed += "<br />"
				end
			end

			@parsed += render(@target_path)

	  	end

	  	private

	  	def render path
	  		rs = ''
	  		isNoneBreakBlock = false
			isCodeBlock = false
			codeBlockContent = ''
			codeBlockName = ''

	  		if File.file? path
				plain = read_file path
				rs += "<h3 class=\"subject\">#{basename(path)}</h3>"
			else
				plain = read_dir path
				plain = "#{read_file default_filepath(path)}<hr />#{@plain}" if File.exist? default_filepath(path)
			end

			images = Dir.glob("#{remove_tail(path)}*").map {|x| x if x =~ /\.(png|jpg)$/i }.compact
			images_idx = 0

			


	  		plain.split(/\n/).each do |line|
				if isCodeBlock 
					if line =~ /^```(.*)?$/
						lexer = Rouge::Lexer.find codeBlockName

						if lexer 
							source = "\n" + codeBlockContent
							formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
							rs += formatter.format(lexer.lex(source))
							Rootz.logger.debug "rouge parsing ... (#{codeBlockName})"
						else
							rs += '<div class="codeblock"><pre>' + "\n\n"
							rs += codeBlockContent
							rs += '</pre></div>'
							Rootz.logger.debug "no parsing ... ()"
						end

						isCodeBlock = false
						codeBlockContent = ''
						codeBlockName = ''
						next
					else
						codeBlockContent += line + "\n"
						next
					end
				else
					if line =~ /^```(.*)?$/
						codeBlockName = $1
						Rootz.logger.debug "code block start ... (#{codeBlockName})"
						isCodeBlock = true
						next
					end

				end

				line.strip!

				# if /^@@\s*(?<title>.*)$/ =~ line
				# 	@subject = title
				# 	next
				# end

				if line =~ /^"""/
					isNoneBreakBlock = isNoneBreakBlock ? false : true
					next
				end

				if line =~ /^---/
					rs += "<hr />"
					next
				end
					
				if line =~ /^(\={1,5})(.*)$/
					rs += "<h#{$1.to_s.length}>#{$2}</h#{$1.to_s.length}>"
					next
				end

				if /``(?<code>.*?)``/ =~ line
					line = "#{special($`)}<span class=\"codeline\">#{safeHtml(code)}</span>#{special($')}"
					line += "<br />" unless isNoneBreakBlock
					rs += line + "\n"
					next
				end

				if /#img#/ =~ line 
					if images_idx >= images.size
						rs += "#{$`}"
						next
					end
					rs += "<img src=\"#{remove_root_prefix(images.fetch(images_idx))}\" />"
					images_idx += 1
					next
				end

				special line

				if line =~ /\(\((?:(.*?)(?: (.*?))?)\)\)/
					rs = Extension.new(@config).build($1, $2)
					line.gsub! $&, rs
				end

				line += "<br />" unless isNoneBreakBlock

				rs += line + "\n"
			end

			"<div class\"content\">#{rs}</div>"
	  	end

	  	def special str
	  		str.gsub! /''(.*?)''/, "<strong>\\1</strong>"
			str.gsub! /__(.*?)__/, "<u>\\1</u>"
			str.gsub! /\/\/(.*?)\/\//, "<i>\\1</i>"	
			str.gsub! /~~(.*?)~~/, "<del>\\1</del>"
			str
	  	end

	  	def link str
	  		# str.gsub! /:(:[*?)*/, 
	  	end

		def safeHtml str
	  		str.gsub! /</, "&lt;"
	  		str.gsub! />/, "&gt;"
	  		str
	  	end

	  	def default_filepath path
			"#{path}_#{File.basename path}" if File.exist? path
	  	end

		def read_file path
			File.read path
		end

		def read_dir path
			pathz = File.join path, "*"
			dirs = []
			files = []
			Rootz.logger.debug "read_dir.path : #{pathz}"
			Dir.glob "#{pathz}" do |file|
				Rootz.logger.debug "read_dir.file : #{file}"
				if File.file? file
					files << "#{convert_link(file)} #{mtime(file)}" if file =~ /\.txt$/
				else
					dirs << convert_link(file)
				end
			end
			dirs += files
			@plain = dirs.join "\n"
		end

		def convert_navi path
			tmp = remove_tail(remove_root_prefix(path))
	        sp = tmp.split /\//

	        atag = []
	        while !sp.empty?
                url = sp.join "/"
                name = sp.pop
                next if name.empty?
                a = "<a href=\"#{url}\">#{name}</a>"
                atag.unshift a
	        end

	        atag.join(" &gt; ")
		end

		def convert_link path
			url = remove_tail(remove_root_prefix(path))
			name = remove_tail(remove_head(remove_root_prefix(basename(path))))

			"<a href=\"#{url}\">#{name}</a>"
		end

		def mtime path 
			datetime = zero_o File.mtime(path).to_s
			"<span class=\"datetime\">#{datetime}</span>"
		end

		def last_dir path
			return "path is not exist!" unless File.exist? path
			tmp = path
			while File.file? tmp
				tmp = File.dirname tmp
			end
			tmp
		end

		def remove_head path
			path.gsub /^\/+/, ''
		end

		def remove_tail path
			path.gsub /(\/|.txt)$/, ''
		end

		def remove_root_prefix path
			return "" if path.empty?

			rs = path.gsub /#{Rootz::PREFIX_PATH}/, ''
		end

		def replace_spliter path
			return "" if path.empty?

			rs = path.sub(/^\//, ":: ").gsub(/\//, " : ")
		end

		def basename path
			File.basename path, ".txt"
		end

		def zero_o str
			str.gsub /0/, 'o'
		end
		
		# def default_image path
		# 	return "" if path == "/"

		# 	path = @default_file_path.empty? ? path : @default_file_path

		# 	if File.file? path
		# 		name = File.basename path, '.txt'
		# 		dir = File.dirname path
		# 		target = File.join "#{dir}", "#{name}.*"
		# 		Dir.glob "#{target}" do |f|
		# 			if f =~ /\.(png|jpg|gif)$/i
		# 				return remove_root_prefix f
		# 			end
		# 		end
		# 	# else
		# 	# 	name = File.basename path, '.txt'
		# 	# 	target = File.join "#{path}", "_#{name}.*"
		# 	# 	Dir.glob "#{target}" do |f|
		# 	# 		if f =~ /\.(png|jpg|gif)$/i
		# 	# 			return remove_root_prefix f
		# 	# 		end
		# 	# 	end
		# 	end

		# 	# header_image File.dirname(path)
		# end

	end



	def self.logger
		@logger ||= Logger.new(STDOUT)

		@logger.formatter = proc do |severity, datetime, progname, msg|
			file = caller[4].sub /^.*\/(.*?)$/, "\\1"
			"#{severity.rjust(8)} #{file.rjust(40)} -- : #{msg}\n"
		end

		@logger
	end


	
end