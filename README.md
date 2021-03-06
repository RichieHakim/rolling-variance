# rolling-variance
Simple code for efficient calculation of online updates to moving/rolling or running variance and mean using Welford's method.
 
The purpose of this script is to compute very fast rolling and running variances and means in a stepwise way. This allows for online processing of incoming data. It is based on a recursive algorithm called Welford's method.

See the demo script for an example of how to use the function. The user's code must hold onto a rolling buffer of values, which must be done outside of this class. 
Note: Future improvements to this code should involve including this rolling buffer within the object. Efficient setting of large array values within MATLAB objects is finicky. If you know how to do it, please get in touch or send me a pull request! RichHakim@gmail.com


RUNNING (accumulating) vs. ROLLING (windowed):
In order to use it as a running (accumulating from the first index) average or variance, just set win_size to be inf and vals_old to []. This method can be used to calculate normal variances and means of arrays that are too big to fit into memory (like on a GPU)!

ARBITRARY DIMENSIONS:
This script allows for an arbitrary number of dimensions to be used, but the rolling dimension must be dim 1.

Rich Hakim 2020.
Most of this code uses a version of Welford's algorithm and was adapted from some Python code I found here:
http://www.taylortree.com/2010/11/running-variance.html 
and here: 
http://www.taylortree.com/2010/06/running-simple-moving-average-sma.html
and here:
http://subluminal.wordpress.com/2008/07/31/running-standard-deviations/
