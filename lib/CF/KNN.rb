module CF
  class KNN < Base
    class Rating < ActiveRecord::Base
      self.primary_key = :id
    end
    
    def rate(movie, customer, date)
      conn = ActiveRecord::Base.connection
      
      my_ratings = []
      
      sim = Pearson.select('movie2')
                   .where("movie1 = #{movie}")
                   .order("pearson desc limit 20")
      
      sim.each do |m|
        rating = Rating.select('rating')
                       .where("movie = #{m.movie2} and customer = #{customer}")
        
        rating.each do |r|
          my_ratings.push(r.rating)
        end
      end
      
      avg = nil
      
      if (my_ratings.empty?)
        avg = 3.6
      else
        avg = my_ratings.sum.to_f / my_ratings.size
      end

      return avg
    end
  end
end