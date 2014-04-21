class Pearson < ActiveRecord::Base
  self.table_name = "pearson"
  
  def self.get_similar_movies(movieid, number_similar)
    similar = Pearson.select("movie1")
            .where("movie2=#{movieid}")
            .order("pearson desc")
            .limit(number_similar)
    
    Movie.find(similar.collect{ |m| m.movie1 })
  end
end