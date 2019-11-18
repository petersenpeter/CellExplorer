package edu.stanford.facs.swing;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class StochasticGradientDescent {

	public final int n_components;
	public final double [][]head_embedding;
	public final double [][]tail_embedding;
	private final int []head;
	private final int []tail;
	private final int n_epochs;
	private final int n_vertices;
	private final double []epochs_per_sample;
	private final double a;
	private final double b;
	private final double initial_alpha;
	public boolean move_other;
	private double alpha;
	private final double BG2S;
	private final double ABNEG2;
	private final double BNEG1;
	private Random r;
	private final int n_1_simplices;
	private final double []epochs_per_negative_sample;
	private final double []epoch_of_next_negative_sample;
	private final double []epoch_of_next_sample;
	private double nTh;
	private int n_epoch;

	public void randomize() {
		r=new Random();
	}

	public double setReports(final double reports) {
		nTh=((double)n_epochs / reports);
		return nTh;
	}
	
	public double getReports() {
		return nTh;
	}
	
	public  StochasticGradientDescent(
			final double [][]head_embedding, final double [][]tail_embedding, 
			final int []head, final int []tail, final int n_epochs, final int n_vertices, 
			final double []epochs_per_sample, final double a, final double b, 
			final double gamma, final double initial_alpha, 
			final int negative_sample_rate){
		this.head_embedding=head_embedding;
		this.tail_embedding=tail_embedding;
		this.head=head;
		this.tail=tail;
		this.n_epochs=n_epochs;
		this.n_vertices=n_vertices;
		this.epochs_per_sample=epochs_per_sample;
		this.a=a;
		this.b=b;
		this.initial_alpha=initial_alpha;
		if (head_embedding.length >0) {
			this.n_components=head_embedding[0].length;
		}else {
			this.n_components=0;
		}
		move_other = head_embedding.length == tail_embedding.length;
		alpha = initial_alpha;
		BG2S=2*gamma* b;
		ABNEG2=-2.0*a*b;
		BNEG1=b-1;
		r=new Random(503l);
		n_1_simplices=epochs_per_sample.length;
		epochs_per_negative_sample=new double[epochs_per_sample.length];
		for (int i=0;i<n_1_simplices;i++) {
			epochs_per_negative_sample[i]=epochs_per_sample[i]/negative_sample_rate;
		}
		epoch_of_next_negative_sample=Arrays.copyOf(epochs_per_negative_sample, n_1_simplices);
		epoch_of_next_sample = Arrays.copyOf(epochs_per_sample, n_1_simplices);
		nTh=((double)n_epochs / (double)EPOCH_REPORTS());
		n_epoch=1;
	}
	
	public int getEpochsDone() {
		return n_epoch;
	}
	
	public int getEpochsToDo() {
		return n_epochs;
	}
	
	public boolean nextEpochs() {
		return nextEpochs(null);
	}
	
	public boolean nextEpochs(final List<Integer>randis) {
		int iRandi=0;
		double []current=new double[n_components];//= {0, 0};
		double []other=new double[n_components];//= {0, 0};
		int n_neg_samples=0;
		double []grad=new double[n_components];//={0, 0};
		double []sub=new double[n_components];//={0, 0};
		double grad_coef=0;
		double dist_squared=0;
		double val=0;
		double alpha4=alpha*4, alphaNeg4=alpha*-4;
		for (int n=this.n_epoch;n<=n_epochs;n++) {
			for (int i=0;i<n_1_simplices;i++) {
				if (epoch_of_next_sample[i]>n) {
					continue;
				}
				final int j=head[i]-1;
				int k=tail[i]-1;
				for (int m=0;m<n_components;m++) {
					current[m]=head_embedding[j][m];
					other[m]=tail_embedding[k][m];
					sub[m]=current[m]-other[m];
				}
				dist_squared=0;
				for (int m=0;m<n_components;m++) {
					dist_squared+=sub[m]*sub[m];
				}
				if (dist_squared>0) {
					grad_coef=(ABNEG2*java.lang.Math.pow(dist_squared, BNEG1))/(a*java.lang.Math.pow(dist_squared, b)+1);
					for (int m=0;m<n_components;m++) {
						val=grad_coef*sub[m];
						if (val>=4) {
							grad[m]=alpha4;
						} else if (val <= -4) {
							grad[m]=alphaNeg4;
						} else {
							grad[m]=val*alpha;
						}
						current[m]=current[m]+grad[m];
					}
					if (move_other) {
						for (int m=0;m<n_components;m++) {
							other[m]=other[m]-grad[m];
							tail_embedding[k][m]=other[m];
						}
					}
				}else {
					for (int m=0;m<n_components;m++) {
						grad[m]=0;
					}
				}
				epoch_of_next_sample[i]+=epochs_per_sample[i];
				n_neg_samples = (int)Math.floor((((double)n) - epoch_of_next_negative_sample[i]) / epochs_per_negative_sample[i]);
				for (int p=0;p<n_neg_samples;p++) {
					if (randis==null) {
						k=r.nextInt(n_vertices);
					} else {
						if (iRandi>=randis.size())
							iRandi=0;
						k=randis.get(iRandi++);
					}
					if (j==k) {
						continue;
					}
					dist_squared=0;
					for (int m=0;m<n_components;m++) {
						other[m]=tail_embedding[k][m];
						sub[m]=current[m]-other[m];
						dist_squared+=sub[m]*sub[m];
					}
					if (dist_squared>0) {
						grad_coef=((BG2S/(0.001+dist_squared)))/(a*java.lang.Math.pow(dist_squared, b)+1);
						for (int m=0;m<n_components;m++) {
							val=grad_coef*sub[m];
							if (val>=4) {
								grad[m]=alpha4;
							} else if (val <= -4) {
								grad[m]=alphaNeg4;
							} else {
								grad[m]=val*alpha;
							}
						}
					} else {
						for (int m=0;m<n_components;m++) {
							grad[m]=4;
						}
					}
					for (int m=0;m<n_components;m++) {
						current[m]=current[m]+(grad[m]);
					}
				}
				for (int m=0;m<n_components;m++) {
					head_embedding[j][m]=current[m];
				}
				//epoch_of_next_negative_sample(i) = epoch_of_next_negative_sample(i)+(n_neg_samples * epochs_per_negative_sample(i));
				epoch_of_next_negative_sample[i]+=n_neg_samples*epochs_per_negative_sample[i];
			}
			alpha = initial_alpha * (1 - (double)((double)n/(double)n_epochs));
			alpha4=alpha*4;
			alphaNeg4=alpha*-4;
			if (Math.floor(((double)n)%nTh)==0) {
				this.n_epoch=n+1;
				if (this.n_epoch<this.n_epochs) {
					return false;
				} else {
					return true;
				}
			}
		}
		return true;
	}
	
	public double [][]getEmbedding(){
		return head_embedding;
	}
	
	public boolean isFinished() {
		return this.n_epoch>=this.n_epochs;
	}
	
	final static boolean DEBUG_RANDI=false;
	final static boolean DEBUG_STATIC_AND_INSTANCE=false;
	public static final int EPOCH_REPORTS() {
		return 20;
	}
	
	public static double[][]Copy(final double[][]in){
		final int rows=in.length;
		final double[][]out=new double[in.length][];
		for (int row=0;row<rows;row++) {
			final int cols=in[row].length;
			out[row]=new double[cols];
			for (int col=0;col<cols;col++) {
				out[row][col]=in[row][col];
			}
		}
		return out;
	}
	
}
