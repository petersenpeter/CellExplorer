package edu.stanford.facs.swing;
/***
 * Author: Stephen Meehan, swmeehan@stanford.edu
 * 
 * Provided by the Herzenberg Lab at Stanford University
 * 
 * License: BSD 3 clause
 */
import java.util.Random;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import javax.swing.JLabel;
import javax.swing.JProgressBar;
import javax.swing.SwingUtilities;

public class Umap {
	private final double [][]head_embedding;
	private final double [][]tail_embedding;
	private final int []head;
	private final int []tail;
	private final int n_epochs;
	private final int n_vertices;
	private final double []epochs_per_sample;
	private final double a;
	private final double b;
	private final double initial_alpha;
	private final boolean move_other;
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
	
	public  Umap(
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
		double []current= {0, 0}, other= {0, 0};
		int n_neg_samples=0;
		double []grad={0, 0};
		double []sub={0, 0};
		double grad_coef=0;
		double dist_squared=0;
		double val=0;
		if (DEBUG_STATIC_AND_INSTANCE) {
			DEBUG_PRINT=true;
		}
		for (int n=this.n_epoch;n<=n_epochs;n++) {
			for (int i=0;i<n_1_simplices;i++) {
				if (epoch_of_next_sample[i]>n) {
					continue;
				}
				final int j=head[i]-1;
				int k=tail[i]-1;
				current[0]=head_embedding[j][0];
				current[1]=head_embedding[j][1];
				other[0]=tail_embedding[k][0];
				other[1]=tail_embedding[k][1];
				sub[0]=current[0]-other[0];
				sub[1]=current[1]-other[1];
				if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
					System.out.print("\t\tk="+k+", "+sub[0]+", "+sub[1]+", "
							+Arrays.toString(current)+", "+ Arrays.toString(other));
					System.out.println();
				}
				dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
				if (dist_squared>0) {
					grad_coef=(ABNEG2*java.lang.Math.pow(dist_squared, BNEG1))/(a*java.lang.Math.pow(dist_squared, b)+1);
					val=grad_coef*sub[0];
					grad[0]=(val>4?4:(val<-4?-4:val))*alpha;
					val=grad_coef*sub[1];
					grad[1]=(val>4?4:(val<-4?-4:val))*alpha;
					current[0]=current[0]+grad[0];
					current[1]=current[1]+grad[1];
					if (move_other) {
						other[0]=other[0]-grad[0];
						other[1]=other[1]-grad[1];
						if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
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
				n_neg_samples = (int)Math.floor((((double)n) - epoch_of_next_negative_sample[i]) / epochs_per_negative_sample[i]);
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
					if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
						System.out.println("\t\t"+k+", "+ Arrays.toString(other));
					}
					sub[0]=current[0]-other[0];
					sub[1]=current[1]-other[1];
					dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
					if (dist_squared>0) {
						grad_coef=((BG2S/(0.001+dist_squared)))/(a*java.lang.Math.pow(dist_squared, b)+1);
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
				if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
					System.out.println("j="+j+", current=["+ current[0]+", "+current[1]+"]");
				}
				//epoch_of_next_negative_sample(i) = epoch_of_next_negative_sample(i)+(n_neg_samples * epochs_per_negative_sample(i));
				epoch_of_next_negative_sample[i]+=n_neg_samples*epochs_per_negative_sample[i];
				DEBUG_PRINT=false;
			}
			alpha = initial_alpha * (1 - (double)((double)n/(double)n_epochs));
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
	static boolean DEBUG_PRINT=true;
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
	
	public static double [][]optimize_layout(
			final double [][]head_embedding, final double [][]tail_embedding, 
			final int []head, final int []tail, final int n_epochs, final int n_vertices, 
			final double []epochs_per_sample, final double a, final double b, 
			final double gamma, final double initial_alpha, 
			final int negative_sample_rate, final Object feedBack, final List<Integer>randis){
		Umap debug=null;
		UmapFloat debugFloat=null;
		List<Integer>debugRandis=new ArrayList<Integer>();
		if (DEBUG_STATIC_AND_INSTANCE) {
			debug=new Umap(Copy(head_embedding), Copy(tail_embedding), head, tail, n_epochs, n_vertices,
					epochs_per_sample, a, b, gamma, initial_alpha, negative_sample_rate);
			debugFloat=new UmapFloat(
					UmapFloat.Copy(head_embedding), 
					UmapFloat.Copy(tail_embedding), 
					head, tail, n_epochs, n_vertices,
					UmapFloat.Copy(epochs_per_sample), 
					(float)a, (float)b, (float)gamma, 
					(float)initial_alpha, negative_sample_rate);
			//debugFloat=new UmapFloat(Copy(head_embedding), Copy(tail_embedding), head, tail, n_epochs, n_vertices,
			//		epochs_per_sample, a, b, gamma, initial_alpha, negative_sample_rate);
		}

		int n_neg_samples=0;
		int iRandi=0;
		final JProgressBar pb;
		final JLabel jlabel;
		final boolean verbose;
		if (feedBack instanceof JLabel) {
			jlabel=(JLabel)feedBack;
			pb=null;
			verbose=true;
		} else if (feedBack instanceof JProgressBar) {
			jlabel=null;
			pb=(JProgressBar)feedBack;
			pb.setMaximum(n_epochs+1);
			verbose=true;
		}else {
			jlabel=null;
			pb=null;
			if (feedBack instanceof Boolean) {
				verbose=(Boolean)feedBack;
			} else {
				verbose=false;
			}
		}
		if (verbose) {
			report(jlabel, pb, 1, "\t0/"+n_epochs +" epochs done");
		}
		final boolean move_other = head_embedding.length == tail_embedding.length;
		double alpha = initial_alpha;
		final double BG2S=2*gamma* b;
		final double ABNEG2=-2.0*a*b;
		final double BNEG1=b-1;
		if (DEBUG_STATIC_AND_INSTANCE) {
			DEBUG_PRINT=true;
		}
		final Random r=new Random(503l);
		final int n_1_simplices=epochs_per_sample.length;
		final double []epochs_per_negative_sample=new double[epochs_per_sample.length];
		for (int i=0;i<n_1_simplices;i++) {
			epochs_per_negative_sample[i]=epochs_per_sample[i]/negative_sample_rate;
		}
		final double []epoch_of_next_negative_sample=Arrays.copyOf(epochs_per_negative_sample, n_1_simplices);
		final double []epoch_of_next_sample = Arrays.copyOf(epochs_per_sample, n_1_simplices);
		double []current= {0, 0}, other= {0, 0};
		double []grad={0, 0};
		double []sub={0, 0};
		double grad_coef=0;
		double dist_squared=0;
		double val=0;
		final double nTh=(n_epochs / (double)EPOCH_REPORTS());
		int j=0, k=0;
		for (int n=1;n<=n_epochs;n++) {
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
				if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
					System.out.print("\t\tk="+k+", "+sub[0]+", "+sub[1]+", "
							+Arrays.toString(current)+", "+ Arrays.toString(other));
					System.out.println();
				}
				dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
				if (dist_squared>0) {
					grad_coef=(ABNEG2*java.lang.Math.pow(dist_squared, BNEG1))/(a*java.lang.Math.pow(dist_squared, b)+1);
					val=grad_coef*sub[0];
					grad[0]=(val>4?4:(val<-4?-4:val))*alpha;
					val=grad_coef*sub[1];
					grad[1]=(val>4?4:(val<-4?-4:val))*alpha;
					current[0]=current[0]+grad[0];
					current[1]=current[1]+grad[1];
					if (move_other) {
						other[0]=other[0]-grad[0];
						other[1]=other[1]-grad[1];
						if (DEBUG_STATIC_AND_INSTANCE && k==-5) {
							System.out.print("\t\tk=5"+ Arrays.toString(other));
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
				n_neg_samples = (int)Math.floor((((double)n) - epoch_of_next_negative_sample[i]) / epochs_per_negative_sample[i]);
				for (int p=0;p<n_neg_samples;p++) {
					//k=12;
					k=r.nextInt(n_vertices);
					if (DEBUG_RANDI) {
						if (randis != null) {
							if (iRandi>=randis.size())
								iRandi=0;
							k=randis.get(iRandi++);
						}
					}
					if (DEBUG_STATIC_AND_INSTANCE) {
						debugRandis.add(k);
					}
					if (j==k) {
						continue;
					}
					other[0]=tail_embedding[k][0];
					other[1]=tail_embedding[k][1];
					if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
						System.out.println("\t\t"+k+", "+ Arrays.toString(other));
					}

					sub[0]=current[0]-other[0];
					sub[1]=current[1]-other[1];
					dist_squared=(sub[0]*sub[0]) + (sub[1]*sub[1]);
					if (dist_squared>0) {
						grad_coef=((BG2S/(0.001+dist_squared)))/(a*java.lang.Math.pow(dist_squared, b)+1);
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

				if (DEBUG_STATIC_AND_INSTANCE && DEBUG_PRINT) {
					System.out.println("j="+j+", current=["+ current[0]+", "+current[1]+"]");
				}
				//epoch_of_next_negative_sample(i) = epoch_of_next_negative_sample(i)+(n_neg_samples * epochs_per_negative_sample(i));
				epoch_of_next_negative_sample[i]+=n_neg_samples*epochs_per_negative_sample[i];
				DEBUG_PRINT=false;
			}
			alpha = initial_alpha * (1 - (double)((double)n/(double)n_epochs));
			if (verbose) {
				final double remainder=((double)n)%nTh;
				if (Math.floor(remainder)==0) {
					final double nn=((double)n)/nTh;
					if (!report(jlabel, pb,nn*nTh, n+"/"+ n_epochs + " epochs done")) {
						return null;
					}
					if (DEBUG_STATIC_AND_INSTANCE) {
						System.out.println();
						System.out.println();
						System.out.println("Instance method now");
						debug.nextEpochs(debugRandis);
						debug.findMisMatch(head_embedding);
						debugFloat.nextEpochs(debugRandis);
						System.out.println();
						System.out.println("Back to static method now");
						debugRandis.clear();
						DEBUG_PRINT=true;
					}
				}
			}
			
		}
		return head_embedding;
	}

	private int findMisMatch(final double[][]other_head_embedding) {
		int misMatches=0;
		for (int row=0;row<head_embedding.length;row++) {
			for (int col=0;col<head_embedding[0].length;col++) {
				double here=other_head_embedding[row][col];
				double there=head_embedding[row][col];
				if (here != there) {
					System.out.println("Yeeeouch!! row="+row+", col="+col);
					misMatches++;
				}
			}
		}
		return misMatches;
	}
	
	static boolean report(final JLabel jlabel, final JProgressBar pb, 
			final double value, final String state) {
		boolean good=true;
		if (pb != null) {
			if (!SwingUtilities.isEventDispatchThread()) {
//				System.out.print("NOT Event dispatch ");
				try {
					SwingUtilities.invokeAndWait(new Runnable() {
						public void run() {
							pb.setValue((int)value);
							pb.setString(state);
							///System.out.print(pb.getValue()+" ");
						}
					});
				} catch (InvocationTargetException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}else {
				System.out.print("Event dispatch ");
				SwingUtilities.invokeLater(new Runnable() {
					public void run() {
						pb.setValue((int)value);
						pb.setString(state);
					}
				});
			}
			//final int mx=pb.getMaximum();
			//System.out.println("Progress bar maximum is "+mx);
			//good=pb.getMaximum()==EPOCH_REPORTS()+1;
		} else if (jlabel != null) {
			if (!SwingUtilities.isEventDispatchThread()) {
				System.out.print("NOT Event dispatch ");
				try {
					SwingUtilities.invokeAndWait(new Runnable() {
						public void run() {
							jlabel.setText(state);
						}
					});
				} catch (InvocationTargetException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}else {
				System.out.print("Event dispatch ");
				SwingUtilities.invokeLater(new Runnable() {
					public void run() {
						jlabel.setText(state);
					}
				});
			}
		} 
		System.out.println("\t" + state);
		return good;
	}
}
