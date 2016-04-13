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
		attr_accessor :subject, :navi, :parsed, :created, :redirect_url

		def initialize path
			puts "\n\n"
			Rootz.logger.info
			@input_url = "/root/#{path}" 
			@input_path = path
			@target_path = "#{File.expand_path "../public/root", __FILE__}/#{@input_path}"

			Rootz.logger.info "@input_path : #{@input_path}"
		end

		def check
			Rootz.logger.info
			

			Rootz.logger.info "target full path : #{@target_path}"

			unless File.exist? @target_path
				if File.exist? "#{@target_path}.rz"
					@target_path = "#{@target_path}.rz"
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

			@navi = convert_navi last_dir(@target_path)
			@subject = @is_file ? basename(@target_path) : "*"
			
		end

		def read
			Rootz.logger.info
			Rootz.logger.info "read @target_path : #{@target_path}"

			if @is_file
				@plain = read_file @target_path

			else
				@plain = read_dir @target_path
			end
		end

		def parse
			Rootz.logger.info

			@parsed = ''
			isNoneBreakBlock = false
			isCodeBlock = false
			codeBlockContent = ''
			codeBlockName = ''

			@plain.split(/\n/).each do |line|

				if isCodeBlock 
					if line =~ /^```(.*)?$/
						lexer = Rouge::Lexer.find codeBlockName

						if lexer 
							source = codeBlockContent
							formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
							result = formatter.format(lexer.lex(source))
							@parsed += result
							Rootz.logger.debug "rouge parsing ... (#{codeBlockName})"
						else
							@parsed += '<div class="codeblock"><pre>'
							@parsed += safeHtml(codeBlockContent)
							# @parsed += "123123"
							# @parsed += codeBlockContent
							@parsed += '</pre></div>'
							Rootz.logger.debug "no parsing ... ()"
						end

						isCodeBlock = false
						codeBlockContent = ''
						codeBlockName = ''
						next
					else
						codeBlockContent += line + "\n"
						Rootz.logger.debug "add line : #{line}"
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

				if /^@@\s*(?<title>.*)$/ =~ line
					@config[:@parsed][:title] = title
					next
				end

				if line =~ /^(@<|@>)/
					next
				end

				if line =~ /^"""/
					isNoneBreakBlock = isNoneBreakBlock ? false : true
					next
				end

				if line =~ /^---/
					@parsed += "<hr />"
					next
				end
					
				if line =~ /^(\={1,5})(.*)$/
					@parsed += "<h#{$1.to_s.length}>#{$2}</h#{$1.to_s.length}>"
					next
				end

				if /``(?<code>.*?)``/ =~ line
					line = "#{special($`)}<span class=\"codeline\">#{safeHtml(code)}</span>#{special($')}"
					line += "<br />" unless isNoneBreakBlock
					@parsed += line + "\n"
					next
				end

				special line

				if line =~ /\(\((?:(.*?)(?: (.*?))?)\)\)/
					rs = Extension.new(@config).build($1, $2)
					line.gsub! $&, rs
				end

				line += "<br />" unless isNoneBreakBlock

				@parsed += line + "\n"
			end
	  	end

	  	private

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
					files << convert_link(file) if file =~ /\.rz$/
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

	        ":: " + atag.join(" : ")
		end

		def convert_link path
			datetime = zero_o File.mtime(path).to_s
			url = remove_tail(remove_root_prefix(path))
			name = remove_tail(remove_head(remove_root_prefix(basename(path))))

			rs = "<a href=\"#{url}\">#{name}</a> <span class=\"datetime\">#{datetime}</span>"

			# # rs = remove_head(rs)
			# rs = remove_tail(rs)
			# rs = replace_spliter(rs)
			# path
			rs
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
			path.gsub /(\/|.rz)$/, ''
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
			File.basename path, ".rz"
		end

		def zero_o str
			str.gsub /0/, 'o'
		end
		
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