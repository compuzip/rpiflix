class Movie < ActiveRecord::Base
	paginates_per 100

	def populateTmdbData!
		unless tmdbid
		  self.tmdbid = findTmdbID

		  if tmdbid > 0
			details = Tmdb::Movie.detail(tmdbid)
			self.tmdbposter = details.poster_path
			if self.tmdbposter.nil?
				# broken link, but other places assume this will be a valid string
				self.tmdbposter = '/no-poster.jpg'
			end
		  end

		  save
		end
	end
	
	private
	def findTmdbID
		# puts "searching for ~" + title.to_s + "~, released " + year.to_s
	
		a = Tmdb::Movie.find(title)

		a.each do |m|
			# puts m
			# puts m.id
			# puts m.title
			# puts m.release_date
			
			rel = Tmdb::Movie.releases(m.id)
			rel["countries"].find_all{|t| t["iso_3166_1"] == "US"}.each do |r|
				# puts r["iso_3166_1"]
				# puts r["release_date"]
				yr = r["release_date"][0,4]
				# puts "yr: " + yr
				
				if (yr.to_i - year).abs < 2
					# puts "******************* FOUND MATCH"
					return m.id
				end
				
			end
		end
		
		return 0
	
	end
	
end