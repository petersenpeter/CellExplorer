package edu.stanford.facs.swing;
/***
 * Author: Stephen Meehan, swmeehan@stanford.edu
 * 
 * Provided by the Herzenberg Lab at Stanford University
 * 
 * License: BSD 3 clause
 */

import java.util.Arrays;
import java.util.List;
import java.util.Random;


public class UmapFloat {
	private final float [][]head_embedding;
	private final float [][]tail_embedding;
	private final int []head;
	private final int []tail;
	private final int n_epochs;
	private final int n_vertices;
	private final float []epochs_per_sample;
	private final float a;
	private final float b;
	private final float initial_alpha;
	private final boolean move_other;
	private float alpha;
	private final float BG2S;
	private final float ABNEG2;
	private final float BNEG1;
	private Random r;
	private final int n_1_simplices;
	private final float []epochs_per_negative_sample;
	private final float []epoch_of_next_negative_sample;
	private final float []epoch_of_next_sample;
	private float nTh;
	private int n_epoch;

	public void randomize() {
		r=new Random();
	}
	
	public float setReports(final float reports) {
		nTh=((float)n_epochs / reports);
		return nTh;
	}
	
	public float getReports() {
		return nTh;
	}
	
	public  UmapFloat(
			final float [][]head_embedding, final float [][]tail_embedding, 
			final int []head, final int []tail, final int n_epochs, final int n_vertices, 
			final float []epochs_per_sample, final float a, final float b, 
			final float gamma, final float initial_alpha, 
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
		move_other = head_embedding.length == tail_embedding.length;
		alpha = initial_alpha;
		BG2S=2*gamma* b;
		ABNEG2=-2.0f*a*b;
		BNEG1=b-1;
		r=new Random(503l);
		n_1_simplices=epochs_per_sample.length;
		epochs_per_negative_sample=new float[epochs_per_sample.length];
		for (int i=0;i<n_1_simplices;i++) {
			epochs_per_negative_sample[i]=epochs_per_sample[i]/negative_sample_rate;
		}
		epoch_of_next_negative_sample=Arrays.copyOf(epochs_per_negative_sample, n_1_simplices);
		epoch_of_next_sample = Arrays.copyOf(epochs_per_sample, n_1_simplices);
		nTh=((float)n_epochs / (float)Umap.EPOCH_REPORTS());
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
		float []current= {0, 0}, other= {0, 0};
		int n_neg_samples=0;
		float []grad={0, 0};
		float []sub={0, 0};
		float grad_coef=0;
		float dist_squared=0;
		float val=0;
		if (Umap.DEBUG_STATIC_AND_INSTANCE) {
			Umap.DEBUG_PRINT=true;
		}
		int j=0, k=0;
		for (int n=this.n_epoch;n<=n_epochs;n++) {
			for (int i=0;i<n_1_simplices;i++) {
				if (epoch_of_next_sample[i]>n) {
					continue;
				}
				j=head[i]-1;
				k=tail[i]-1;
				current[0]=head_embedding[j][0];
				current[1]=head_embedding[j][1];
				other[0]=tail_embedding[k][0];
				other[1]=tail_embedding[k][1];
				sub[0]=current[0]-other[0];
				sub[1]=current[1]-other[1];
				if (Umap.DEBUG_STATIC_AND_INSTANCE && Umap.DEBUG_PRINT) {
					System.out.print("\t\tk="+k+", "+sub[0]+", "+sub[1]+", "
							+Arrays.toString(current)+", "+ Arrays.toString(other));
					System.out.println();
				}
				dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
				if (dist_squared>0) {
					grad_coef=(ABNEG2*(float)java.lang.Math.pow(dist_squared, BNEG1))
							/(a*(float)java.lang.Math.pow(dist_squared, b)+1);
					val=grad_coef*sub[0];
					grad[0]=(val>4?4:(val<-4?-4:val))*alpha;
					val=grad_coef*sub[1];
					grad[1]=(val>4?4:(val<-4?-4:val))*alpha;
					current[0]=current[0]+grad[0];
					current[1]=current[1]+grad[1];
					if (move_other) {
						other[0]=other[0]-grad[0];
						other[1]=other[1]-grad[1];
						if (Umap.DEBUG_STATIC_AND_INSTANCE && Umap.DEBUG_PRINT) {
							System.out.print("\t\tk=5, tail="+ Arrays.toString(other));
							System.out.println();
						}
						tail_embedding[k][0]=other[0];
						tail_embedding[k][1]=other[1];
					}
				}else {
					grad[0]=0;
					grad[1]=0;
				}
				epoch_of_next_sample[i]+=epochs_per_sample[i];
				n_neg_samples = (int)Math.floor((((float)n) - epoch_of_next_negative_sample[i]) / epochs_per_negative_sample[i]);
				for (int p=0;p<n_neg_samples;p++) {
					//k=12;
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

					other[0]=tail_embedding[k][0];
					other[1]=tail_embedding[k][1];
					if (Umap.DEBUG_STATIC_AND_INSTANCE && Umap.DEBUG_PRINT) {
						System.out.println("\t\t"+k+", "+ Arrays.toString(other));
					}
					sub[0]=current[0]-other[0];
					sub[1]=current[1]-other[1];
					dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
					if (dist_squared>0) {
						grad_coef=((BG2S/(0.001f+dist_squared)))/(a*(float)java.lang.Math.pow(dist_squared, b)+1);
						val=grad_coef*sub[0];
						grad[0]=(val>4?4:(val<-4?-4:val))*alpha;
						val=grad_coef*sub[1];
						grad[1]=(val>4?4:(val<-4?-4:val))*alpha;
					} else {
						grad[0]=4;
						grad[1]=4;
					}
					current[0]=current[0]+(grad[0]);
					current[1]=current[1]+(grad[1]);
				}
				head_embedding[j][0]=current[0];
				head_embedding[j][1]=current[1];
				epoch_of_next_negative_sample[i]+=n_neg_samples*epochs_per_negative_sample[i];
				if (Umap.DEBUG_STATIC_AND_INSTANCE && Umap.DEBUG_PRINT) {
					System.out.println("j="+j+", current=["+ current[0]+", "+current[1]+"]");
					Umap.DEBUG_PRINT=false;
				}
				
			}
			alpha = initial_alpha * (1 - (float)((float)n/(float)n_epochs));
			if (Math.floor(((float)n)%nTh)==0) {
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
	
	public float [][]getEmbedding(){
		return head_embedding;
	}
	
	public boolean isFinished() {
		return this.n_epoch>=this.n_epochs;
	}

	public static float[][]Copy(final double[][]in){
		final int rows=in.length;
		final float[][]out=new float[rows][];
		for (int row=0;row<rows;row++) {
			final int cols=in[row].length;
			out[row]=new float[cols];
			for (int col=0;col<cols;col++) {
				out[row][col]=(float)in[row][col];
			}
		}
		return out;
	}

	public static float[]Copy(final double[]in){
		final int N=in.length;
		final float[]out=new float[N];
		for (int i=0;i<N;i++) {
			out[i]=(float)in[i];
		}
		return out;
	}
}
