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
	private final double[][] customerFeatures;
	
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
		
		customer_map = new int[maxCustomer + 1];
		
		System.out.println("learn rate: " + learnRate + ", regRate: " + regRate);
	}
	
	public void setRatings(short[] rating_movie, int[] rating_customer, byte[] rating) {
		for(int x = 0; x < rating_rating.length; x++) {
			this.rating_movie[x] = rating_movie[x];
			this.rating_customer[x] = rating_customer[x];
			this.rating_rating[x] = rating[x];
		}		
	}
	
	public void setCustomerMap(int[] customerMap) {
		for(int x = 0; x < customer_map.length; x++)
			customer_map[x] = customerMap[x];
	}
	
	public void setMovieFeatures(double[][] movieFeatures) {
		for(int f = 0; f < features; f++)
			for(int m = 0; m < movieFeatures.length; m++)
				this.movieFeatures[f][m] = movieFeatures[m][f + 1];
	}
	
	public void setCustomerFeatures(double[][] customerFeatures) {
		for(int f = 0; f < features; f++)
			for(int c = 0; c < customerFeatures.length; c++)
				this.customerFeatures[f][c] = customerFeatures[c][f + 1];
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
		}
		
		return sse;
	}
}
