package org.rpiflix.svd;

public class SVD {
	private final short[] rating_movie;
	private final int[] rating_customer;
	private final byte[] rating_rating;
	
	private final int[] customer_map;
	
	private final double learnRate;
	private final double regRate;
	
	private final int features;
	
	private final double[][] movieFeatures;
	private final boolean[] changedMovie;
//	private final short[] movieIDs;
	
	private final double[][] customerFeatures;
	private final boolean[] changedCustomer;
//	private final int[] customerIDs;
	
	public SVD(int features, int rating_count, int movie_count, int customer_count,
			int maxCustomer,
			double learnRate, double regRate) {

		rating_movie = new short[rating_count];
		rating_customer = new int[rating_count];
		rating_rating = new byte[rating_count];
		
		this.learnRate = learnRate;
		this.regRate = regRate;
		
		this.features = features;
		
		movieFeatures = new double[features][movie_count];
		customerFeatures = new double[features][customer_count];
		
		changedMovie = new boolean[movie_count];
		changedCustomer = new boolean[customer_count];
		
		customer_map = new int[maxCustomer + 1];
		
		System.out.println("learn rate: " + learnRate + ", regRate: " + regRate);
	}
	
	public void setRatings(int offset, short[] rating_movie, int[] rating_customer, byte[] rating) {
		System.arraycopy(rating_movie, 0, this.rating_movie, offset, rating_movie.length);
		System.arraycopy(rating_customer, 0, this.rating_customer, offset, rating_customer.length);
		System.arraycopy(rating, 0, this.rating_rating, offset, rating.length);
		
//		for(int x = 0; x < rating_movie.length; x++) {
//			this.rating_movie[offset + x] = rating_movie[x];
//			this.rating_customer[offset + x] = rating_customer[x];
//			this.rating_rating[offset + x] = rating[x];
//		}		
	}
	
	public int minRating() {
		int min = 10;
		
		for(int x = 0; x < rating_rating.length; x++)
			if(rating_rating[x] < min)
				min = rating_rating[x];
		
		return min;
	}
	
	public int maxRating() {
		int max = -1;
		
		for(int x = 0; x < rating_rating.length; x++)
			if(rating_rating[x] > max)
				max = rating_rating[x];
		
		return max;
	}
	
	
//	public void setRatingMovies(short[] rating_movie) {
//		for(int x = 0; x < rating_movie.length; x++)
//			this.rating_movie[x] = rating_movie[x];
//	}
//	
//	public void setRatingCustomers(int[] rating_customer) {
//		for(int x = 0; x < rating_customer.length; x++)
//			this.rating_customer[x] = rating_customer[x];
//	}
//	
//	public void setRatingRatings(byte[] rating_rating) {
//		for(int x = 0; x < rating_rating.length; x++)
//			this.rating_rating[x] = rating_rating[x];
//	}
	
	public void setCustomerMap(int[] customerMap) {
		for(int x = 0; x < customer_map.length; x++)
			customer_map[x] = customerMap[x];
	}
	
	public void setMovieFeatures(double[][] movieFeatures) {
		for(int f = 0; f < features; f++)
			for(int m = 0; m < movieFeatures.length; m++)
				this.movieFeatures[f][m] = movieFeatures[m][f + 1];
	}
	
	public double[][] getMovieFeatures() {
		double[][] ret = new double[movieFeatures[0].length][features];
		
		for(int f = 0; f < features; f++)
			for(int m = 0; m < movieFeatures[0].length; m++)
				ret[m][f] = movieFeatures[f][m];
		
		return ret;
	}
	
	public boolean[] getChangedMovies() {
		return changedMovie;
	}
	
	public void setCustomerFeatures(double[][] customerFeatures) {
		for(int f = 0; f < features; f++)
			for(int c = 0; c < customerFeatures.length; c++)
				this.customerFeatures[f][c] = customerFeatures[c][f + 1];
	}
	
	public double[][] getCustomerFeatures() {
		double[][] ret = new double[customerFeatures[0].length][features];
		
		for(int f = 0; f < features; f++)
			for(int c = 0; c < customerFeatures[0].length; c++)
				ret[c][f] = customerFeatures[f][c];
		
		return ret;
	}
	
	public boolean[] getChangedCustomers() {
		return changedCustomer;
	}
	
	public final double calcPred(final int movie, final int customer) {
		final int cID = customer_map[customer];
		final int mID = movie - 1;
		
		double pred = 0.0;
		for(int f = 0; f < features; f++)			
			pred += movieFeatures[f][mID] * customerFeatures[f][cID];
		
		return pred;
	}
	
	public double calcSSE() {
		double sse = 0.0;
		
		for(int r = 0; r < rating_rating.length; r++) {			
			final double pred = calcPred(rating_movie[r], rating_customer[r]);
			
			final double err = rating_rating[r] - pred;
			
			sse += err * err;
		}
		
		return sse;
	}
	
	public double train() {
		double sse = 0.0;
		
		for(int r = 0; r < rating_rating.length; r++) {
			final int cID = customer_map[rating_customer[r]];
			final int mID = rating_movie[r] - 1;
			
			double pred = 0.0;
			for(int f = 0; f < features; f++)
				pred += movieFeatures[f][mID] * customerFeatures[f][cID];
			
			final double err = rating_rating[r] - pred;
			
			sse += err * err;
			
			for(int f = 0; f < features; f++) {
				final double mtemp = movieFeatures[f][mID];
				final double ctemp = customerFeatures[f][cID];
				
				movieFeatures[f][mID] += learnRate * (err * ctemp - regRate * mtemp);
				customerFeatures[f][cID] += learnRate * (err * mtemp - regRate * ctemp);
			}
			
			changedMovie[mID] = true;
			changedCustomer[cID] = true;
		}
		
		return Math.sqrt(sse / rating_rating.length);
	}
}
